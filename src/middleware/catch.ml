module Dream =
struct
  include Dream_pure.Inmost
  module Log = Log
end

let log =
  Dream.Log.source "dream.catch"



(* TODO LATER Once there are many getters in the main API, finish this out. The
   main question right now is printing the headers and the final context. *)
(* TODO LATER Add ~template argument to main catch handler. *)
(* TODO LATER Expose all helpers, so that the user can re-compose them. *)
(* TODO DOC The dump needs escaping if included in HTML. *)
let dump request =
  let final_request = !(request.Dream.final) in

  let headers =
    Dream.headers final_request
    |> List.map (fun (name, value) -> name ^ ": " ^ value)
    |> String.concat "\n"
  in

  (* TODO LATER Sort the list. *)
  let locals =
    Dream.Local.fold (fun (Dream.Local.B (key, value)) list ->
      match Dream.Local.Key.info key with
      | None -> list
      | Some format -> format value::list)
      final_request.scope []
    |> List.map (fun (name, value) -> name ^ ": " ^ value)
    |> String.concat "\n"
  in

  let globals =
    Dream.Global.fold (fun (Dream.Global.B (key, value)) list ->
      match Dream.Global.Key.info key with
      | None -> list
      | Some format -> format value::list)
      !(final_request.specific.Dream.app) []
    |> List.map (fun (name, value) -> name ^ ": " ^ value)
    |> String.concat "\n"
  in

  headers ^ "\n\n" ^ locals ^ "\n\n" ^ globals

(* TODO LATER Expose the error handlers for users to forward to in debug
   mode. *)
let default_on_error ~debug request response =

  (* If the response already hss a body, leave it alone. Otherwise, set its body
     to the (English) reason string corresponding to the response code. If in
     debug mode, append a ton of information about the request. *)
  if Dream.has_body response then
    Lwt.return response
  else begin

    let reason = Dream.reason response in
    let reason =
      if debug then
        reason ^ "\n\n" ^ dump request
      else
        reason
    in

    Lwt.return (Dream.with_body reason response)
  end

let default_on_exn ~debug request exn =

  let exn = Printexc.to_string exn in
  let backtrace = Printexc.get_backtrace () in

  log.error (fun log -> log "Caught: %s" exn);
  backtrace |> Dream.Log.iter_backtrace (fun line ->
    log.error (fun log -> log "%s" line));

  let reason =
    if not debug then
      Dream.status_to_string `Internal_server_error
    else
      exn ^ "\n" ^ backtrace ^ "\n\n" ^ dump request
  in

  Dream.respond ~status:`Internal_server_error reason



let catch
    ?(on_error = default_on_error)
    ?(on_exn = default_on_exn)
    ?(debug = false)
    next_handler request =

  Lwt.try_bind

    (fun () ->
      next_handler request)

    (fun response ->
      let status = Dream.status response in

      if Dream.is_client_error status || Dream.is_server_error status then
        on_error ~debug request response
      else
        Lwt.return response)

    (fun exn ->
      on_exn ~debug request exn)



(* TODO DOC Encourage people to return empty error responses as a default
   scheme, and catch them all at the top. *)
(* TODO LATER Beautiful default formatters. *)
