(* https://ulrikstrid.github.io/ocaml-cookie/cookie/Cookie/index.html
   https://ulrikstrid.github.io/ocaml-cookie/session-cookie-lwt/Session_cookie_lwt/Make/index.html
   https://github.com/inhabitedtype/ocaml-session#readme *)

(* TODO LATER Achieve in-memory sessions. *)
(* TODO LATER Achieve database sessions. *)
(* TODO LATER Factor out into a separate library. *)

(* TODO LATER What is the point of the value? *)

(* TODO LATER Expiration, refresh. *)

(* TODO LATER Invalidation. *)

(* TODO Does HTTP/2, for example, allow connection-based session validation, as
   an optimization? Is that secure? *)

(* https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html *)

module Dream =
struct
  include Dream_pure.Inmost
  module Log = Log
  let add_set_cookie = Cookie.add_set_cookie
  let base64url = Microformat.base64url
  let cookie_option = Cookie.cookie_option
  let random = Random.random
end

let name = "dream.session"
(* module Log = (val Fw.Logger.create_log name : Fw.Logger.LOG) *)

let cookie = "session"

(* TODO LATER Rearrange, this is just a calque of the earlier webapp session
   middleware. *)
let log = Dream.Log.source name

type stored = {
  person : string option;
}

type t = {
  key : string;
  data : stored;
}

let sessions = Hashtbl.create 256

let session_key {key; _} =
  key

let person {data = {person; _}; _} =
  person

(* The first 48 bits of the key are there just to identify it in the logs. *)
let identify_key k =
  String.sub k 0 8

let read_and_touch ~key =
  Hashtbl.find_opt sessions key
  (* TODO LATER Need to support OCaml 4.04 or so. No real need for Option
     module. *)
  |> Option.map (fun data -> {key; data})
  |> Lwt.return

let create ?person () =
  (* TODO LATER Drema really needs a helper for base64url encoding to avoid
     mistakes at places like this. *)
  (* TODO Need to add Dream.random as a high-quality entropy source. *)
  let key = Dream.base64url (Dream.random 36) in
  let data = {person} in
  Hashtbl.replace sessions key data;
  log.debug (fun m -> m "Session %s created" (identify_key key));
  Lwt.return {key; data}

(* TODO LATER Rename this variable. *)
(* TODO LATER Decorate the variable with metadata for the debugger. *)
let key =
  Dream.new_local ()

(* TODO Replace find_exn by find. *)
(* TODO Rename. *)
(* TODO A neat error message if the session is missing when expected. *)
let get request =
  Dream.local key request

let switch ?person response =
  let open Lwt.Infix in

  create ?person () >>= fun session ->

  Lwt.return (Dream.with_local key session response, session)
  (* TODO This return is awkward. Should probably set the sesion on the request,
     not the response, and then it is not necessary to also return it to the
     caller. The caller can get it from the response, if needed. *)

(* TODO Rename loggers from m to log. *)
let check handler request =
  let open Lwt.Infix in

  begin match Dream.cookie_option cookie request with
  | None ->
    log.debug (fun m -> m ~request "Session missing");
    create () >>= fun session ->
    Lwt.return (session, true)
  | Some incoming_key ->
    read_and_touch ~key:incoming_key >>= fun session ->
    match session with
    | None ->
      log.debug (fun m ->
        m ~request "Session %s stale" (identify_key incoming_key));
      create () >>= fun session ->
      Lwt.return (session, true)
    | Some session ->
      log.debug (fun m ->
        m ~request "Session %s valid" (identify_key incoming_key));
      Lwt.return (session, false)
  end
  >>= fun (session, fresh) ->

  handler (Dream.with_local key session request)
  >>= fun response ->

  let outgoing_key =
    match Dream.local_option key response, fresh with
    | Some session, _ -> Some (session_key session)
    | None, true -> Some (session_key session)
    | None, false -> None
  in

  (* TODO Add ~secure when running under HTTPS. *)
  let response =
    match outgoing_key with
    | None -> response
    | Some outgoing_key ->
      log.debug (fun m -> m ~request
        "Session %s sent" (identify_key outgoing_key));
      (* TODO Need all the cookie options: HttpOnly, Scope based on the prefix,
         well not the domain.  *)
        (* ~http_only:true ~scope:(Uri.of_string ((Prefix.get req) "/"))
        (cookie, outgoing_key) resp *)
      (* TODO Need to replace_set_cookie rather than add_set_cookie. *)
      Dream.add_set_cookie cookie outgoing_key response
  in

  Lwt.return response

let destroy request =
  let {key; _} = get request in
  Hashtbl.remove sessions key;
  Lwt.return_unit

let key = session_key

let identify req =
  identify_key (session_key (get req))
