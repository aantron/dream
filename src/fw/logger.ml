(* Should the logger be included? Yes, because every app will need logging...
   This carries with it dependencies:

   OCAMLBUILD

   can use logs from:

   TODO

   https://github.com/dune-universe/opam-overlays

   Will also have to take fmt from there.
    *)

let name = "mw.logger"

(* TODO Need to add metadata. *)
let key =
  Opium.Context.Key.create (name, fun _ -> assert false)

let request_id (req : Opium.Request.t) =
  Opium.Context.find_exn key req.env

let tag =
  Logs.Tag.def "request" (fun formatter req ->
    Format.pp_print_int formatter (request_id req))

type ('a, 'b) log =
  ((?req:Opium.Request.t ->
   ('a, Stdlib.Format.formatter, unit, 'b) Stdlib.format4 -> 'a) -> 'b) ->
    unit

module type LOG =
sig
  val err : ('a, unit) log
  val warn : ('a, unit) log
  val info : ('a, unit) log
  val debug : ('a, unit) log
end

let create_log name =
  let forward (log : _ Logs.log) =
    fun k ->
      log (fun m ->
        k (fun ?req rest ->
          let tags =
            match req with
            | None -> Logs.Tag.empty
            | Some req -> Logs.Tag.empty |> Logs.Tag.add tag req
          in
          m ~tags rest))
  in
  let (module Log) = Logs.src_log (Logs.Src.create name) in
  (module struct
    let err k = forward Log.err k
    let warn k = forward Log.warn k
    let info k = forward Log.info k
    let debug k = forward Log.debug k
  end : LOG)

module Log = (val create_log name : LOG)

let lwt_key : Opium.Request.t Lwt.key = Lwt.new_key ()

let last_request_id = ref 0

(* Logging client IP depends on
   https://github.com/rgrinberg/opium/issues/264. *)

let log : Type.middleware = fun handler req ->
  (* Opium.App.middleware @@ Rock.Middleware.create ~name
      ~filter:begin fun handler req -> *)
  incr last_request_id;
  let id = !last_request_id in
  let req = {req with env = Opium.Context.add key id req.env} in

  let user_agent =
    Opium.Request.headers "User-Agent" req |> String.concat " " in

  Log.info (fun m -> m ~req "%a %s %s"
    Opium.Method.pp req.meth req.target user_agent);

  let start = Unix.gettimeofday () in

  Lwt.try_bind
    (fun () -> Lwt.with_value lwt_key (Some req) (fun () -> handler req))
    (fun resp ->
      let elapsed = Unix.gettimeofday () -. start in

      let location =
        if Opium.Status.is_redirection resp.status then
          Opium.Response.location resp
          |> Option.value ~default:"<no Location header>"
          |> (^) " "
        else
          ""
      in

      Log.info (fun m -> m ~req "%a%s in %.0f μs"
        Opium.Status.pp_hum resp.status location (elapsed *. 1e6));
      Lwt.return resp)
    (fun exn ->
      Log.err (fun m -> m ~req "500: aborted by %s" (Printexc.to_string exn));
      Lwt.fail exn)

let reporter () =
  let buf_fmt ~like =
    let b = Buffer.create 512 in
    Fmt.with_buffer ~like b,
    fun () ->
      let m = Buffer.contents b in
      Buffer.reset b;
      m
  in
  let app, app_flush = buf_fmt ~like:Fmt.stdout in
  let dst, dst_flush = buf_fmt ~like:Fmt.stderr in

  let report src level ~over k msgf =
    let formatter = if level = Logs.App then app else dst in
    let k' _ =
      Lwt.async begin fun () ->
        Lwt.finalize
          (fun () ->
            match level with
            | Logs.App -> Lwt_io.write Lwt_io.stdout (app_flush ())
            | _ ->        Lwt_io.write Lwt_io.stderr (dst_flush ()))
          (fun () ->
            over ();
            Lwt.return_unit)
      end;
      k ()
    in
    let level_style, level =
      match level with
      | Logs.App ->     `Cyan,    "    "
      | Logs.Error ->   `Red,     "EROR"
      | Logs.Warning -> `Yellow,  "WARN"
      | Logs.Info ->    `Green,   "INFO"
      | Logs.Debug ->   `Blue,    "DBUG"
    in
    msgf @@ fun ?header ?tags fmt ->
      ignore header;
      let time =
        let open Unix in
        let unix_time = gettimeofday () in
        let time = localtime unix_time in
        let fraction = fst (modf unix_time) *. 1000. in
        let fraction = if fraction > 999. then 999. else fraction in
        Printf.sprintf "%02i.%02i.%02i %02i:%02i:%02i.%03.0f"
          time.tm_mday time.tm_mon ((time.tm_year + 1900) mod 100)
          time.tm_hour time.tm_min time.tm_sec fraction
      in
      let source =
        let width = 15 in
        if Logs.Src.equal src Logs.default then
          String.make width ' '
        else
          let name = Logs.Src.name src in
          if String.length name > width then
            String.sub name (String.length name - width) width
          else
            (String.make (width - String.length name) ' ') ^ name
      in
      let request = Option.bind tags (Logs.Tag.find tag) in
      let request =
        match request with
        | Some _ -> request
        | None -> Lwt.get lwt_key
      in
      let request, request_style =
        match request with
        | None -> "", `White
        | Some req ->
          let id = request_id req in
          " REQ " ^ (string_of_int id),
          if id mod 2 = 0 then `Cyan else `Magenta
      in
      Format.kfprintf k' formatter ("%a %s %a%a @[" ^^ fmt ^^ "@]@.")
        Fmt.(styled `Faint string) time
        source
        Fmt.(styled level_style string) level
        Fmt.(styled request_style (styled `Italic string)) request
  in
  {Logs.report}
