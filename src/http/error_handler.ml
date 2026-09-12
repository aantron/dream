(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/camlworks/dream.

   Copyright 2021 Anton Bachin *)



module Catch = Dream__server.Catch
module Error_template = Dream__server.Error_template
module Method = Dream_pure.Method
module Helpers = Dream__server.Helpers
module Log = Dream__server.Log
module Message = Dream_pure.Message
module Status = Dream_pure.Status
module Stream = Dream_pure.Stream



(* TODO DOC The error handler is almost a middleware. But it needs to plug in to
   the lower levels of the framework. Also, a benefit of it not being directly
   a middleware is that it cannot wrongly appear composed into deeper levels of
   an app. *)

let log =
  Log.sub_log "dream.http"

let select_log = function
  | `Error -> log.error
  | `Warning -> log.warning
  | `Info -> log.info
  | `Debug -> log.debug



let dump (error : Catch.error) =
  let buffer = Buffer.create 4096 in
  let p format = Printf.bprintf buffer format in

  begin match error.condition with
  | `Response response ->
    let status = Message.status response in
    p "%i %s\n" (Status.status_to_int status) (Status.status_to_string status)

  | `String "" ->
    p "(Library error without description payload)\n"

  | `String string ->
    p "%s\n" string

  | `Exn exn ->
    let backtrace = Printexc.get_backtrace () in
    p "%s\n" (Printexc.to_string exn);
    backtrace |> Log.iter_backtrace (p "%s\n")
  end;

  p "\n";

  let layer =
    match error.layer with
    | `TLS -> "TLS library"
    | `HTTP -> "HTTP library"
    | `HTTP2 -> "HTTP2 library"
    | `WebSocket -> "WebSocket library"
    | `App -> "Application"
  in

  let blame =
    match error.caused_by with
    | `Server -> "Server"
    | `Client -> "Client"
  in

  let severity =
    match error.severity with
    | `Error -> "Error"
    | `Warning -> "Warning"
    | `Info -> "Info"
    | `Debug -> "Debug"
  in

  p "From: %s\n" layer;
  p "Blame: %s\n" blame;
  p "Severity: %s" severity;

  begin match error.client with
  | None -> ()
  | Some client -> p "\n\nClient: %s" client
  end;

  begin match error.request with
  | None -> ()
  | Some request ->
    p "\n\n%s %s"
      (Method.method_to_string (Message.method_ request))
      (Message.target request);

    Message.all_headers request
    |> List.iter (fun (name, value) -> p "\n%s: %s" name value);

    Message.fold_fields (fun name value first ->
      if first then
        p "\n";
      p "\n%s: %s" name value;
      false)
      true
      request
    |> ignore
  end;

  Buffer.contents buffer

(* TODO LATER Some library is registering S-exp-based printers for expressions,
   which are calling functions that use exceptions during parsing, which are
   clobbering the backtrace. *)
let customize template (error : Catch.error) =

  (* First, log the error. *)

  let log_handler condition (error : Catch.error) =
     let client =
       match error.client with
       | None -> ""
       | Some client ->  " (" ^ client ^ ")"
     in

     let layer =
       match error.layer with
       | `TLS -> ["TLS" ^ client]
       | `HTTP -> ["HTTP" ^ client]
       | `HTTP2 -> ["HTTP/2" ^ client]
       | `WebSocket -> ["WebSocket" ^ client]
       | `App -> []
     in

     let description, backtrace =
       match condition with
       | `String string -> string, ""
       | `Exn exn ->
         let backtrace = Printexc.get_backtrace () in
         Printexc.to_string exn, backtrace
     in

     let message = String.concat ": " (layer @ [description]) in

     select_log error.severity (fun log ->
       log ?request:error.request "%s" message);
     backtrace |> Log.iter_backtrace (fun line ->
       select_log error.severity (fun log ->
         log ?request:error.request "%s" line))
  in

  begin match error.condition with
  | `Response _ -> ()
  (* TODO Is this the right place to handle lower level connection resets? *)
  | `Exn (Unix.Unix_error (Unix.ECONNRESET, _, _)) ->
    let condition = `String "Connection Reset at Client" in
    let severity = `Info in
    log_handler condition {error with condition; severity}
  | `String _ | `Exn _ as condition ->
    log_handler condition error
  end;

  (* If Dream will not send a response for this error, we are done after
     logging. Otherwise, if debugging is enabled, gather a bunch of information.
     Then, call the template, and return the response. *)

  if not error.will_send_response then
    Lwt.return_none

  else
    let debug_dump = dump error in

    let response =
      match error.condition with
      | `Response response -> response
      | _ ->
        let status =
          match error.caused_by with
          | `Server -> `Internal_Server_Error
          | `Client -> `Bad_Request
        in
        Message.response ~status Stream.empty Stream.null
    in

    (* No need to catch errors when calling the template, because every call
       site of the error handler already has error handlers for catching double
       faults. *)
    let%lwt response = template error debug_dump response in
    Lwt.return (Some response)



let default_template _error _debug_dump response =
  Lwt.return response

let debug_template _error debug_dump response =
  let status = Message.status response in
  let code = Status.status_to_int status
  and reason = Status.status_to_string status in
  Message.set_header response "Content-Type" Dream_pure.Formats.text_html;
  Message.set_body response (Error_template.render ~debug_dump ~code ~reason);
  Lwt.return response

let default =
  customize default_template

let debug_error_handler =
  customize debug_template



(* Error reporters (called in various places by the framework). *)



let double_faults f default =
  Lwt.catch f begin fun exn ->
    let backtrace = Printexc.get_backtrace () in

    log.error (fun log ->
      log "Error handler raised: %s" (Printexc.to_string exn));

    backtrace
    |> Log.iter_backtrace (fun line ->
      log.error (fun log -> log "%s" line));

    default ()
  end

(* If the user's handler fails to provide a response, return an empty 500
   response. Don't return the original response we passed to the error handler,
   because the app may have been using that to communicate some internal
   information to the error handler. Not returning a response from the handler
   is a programming error, so it's probably fine to return a generic server
   error. *)
let respond_with_option f =
  double_faults
    (fun () ->
      f ()
      |> Lwt.map (function
        | Some response -> response
        | None ->
          Message.response
            ~status:`Internal_Server_Error Stream.empty Stream.null))
    (fun () ->
      Message.response ~status:`Internal_Server_Error Stream.empty Stream.null
      |> Lwt.return)



(* In the functions below, the first row or set of arguments comes from the
   framework, by partial application, and the second row or set (after "fun")
   comes from the state machine (http/af, h2, websocket/af, ocaml-tls, etc.) *)

(* This error handler actually *is* a middleware, but it is just one pathway for
   reaching the centralized error handler provided by the user, so it is built
   into the framework. *)

let app
    user's_error_handler =
    fun error ->

  respond_with_option (fun () -> user's_error_handler error)



let default_response = function
  | `Server ->
    Message.response ~status:`Internal_Server_Error Stream.empty Stream.null
  | `Client ->
    Message.response ~status:`Bad_Request Stream.empty Stream.null

let httpaf
    user's_error_handler =
    fun client_address ?request error start_response ->

  ignore (request : Httpun.Request.t option);
  (* TODO LATER Should factor out the request translation function and use it to
     partially recover the request info. *)

  let condition, severity, caused_by =
    match error with
    | `Exn exn ->
      `Exn exn,
      `Error,
      `Server

    | `Bad_request
    | `Bad_gateway ->
      `String "Bad request",
      `Warning,
      `Client

    | `Internal_server_error ->
      `String "Content-Length missing or negative",
      `Error,
      `Server
  in

  let error = {
    Catch.condition;
    layer = `HTTP;
    caused_by;
    request = None;
    response = None;
    client = Some (Adapt.address_to_string client_address);
    severity;
    will_send_response = true;
  } in

  Lwt.async begin fun () ->
    double_faults begin fun () ->
      let%lwt response = user's_error_handler error in

      let response =
        match response with
        | Some response -> response
        | None -> default_response caused_by
      in

      let headers = Httpun.Headers.of_list (Message.all_headers response) in
      let body = start_response headers in

      Adapt.forward_body response body;

      Lwt.return_unit
    end
      Lwt.return
  end



let h2
    user's_error_handler =
    fun client_address ?request error start_response ->

  ignore request; (* TODO Recover something from the request. *)

  let condition, severity, caused_by =
    match error with
    | `Exn exn ->
      `Exn exn,
      `Error,
      `Server

    | `Bad_request ->
      `String "Bad request",
      `Warning,
      `Client

    | `Internal_server_error ->
      `String "Content-Length missing or negative",
      `Error,
      `Server
      (* TODO LATER When does H2 raise `Internal_server_error? *)
  in

  let error = {
    Catch.condition;
    layer = `HTTP2;
    caused_by;
    request = None;
    response = None;
    client = Some (Adapt.address_to_string client_address);
    severity;
    will_send_response = true;
  } in

  Lwt.async begin fun () ->
    double_faults begin fun () ->
      let%lwt response = user's_error_handler error in

      let response =
        match response with
        | Some response -> response
        | None -> default_response caused_by
      in

      let headers = H2.Headers.of_list (Message.all_headers response) in
      let body = start_response headers in

      Adapt.forward_body_h2 response body;

      Lwt.return_unit
    end
      Lwt.return
  end



(* The protocol state machines (http/af, etc.) try to pass all errors generated
   inside their request handlers to their own error handlers. In addition, all
   user code run by Dream is wrapped in Lwt.catch to catch all user errors.
   However, SSL protocol errors are not wrapped in any of these, so we add an
   edditional top-level handler to catch them. *)
let tls
    user's_error_handler client_address error =

  let error = {
    Catch.condition = `Exn error;
    layer = `TLS;
    caused_by = `Client;
    request = None;
    response = None;
    client = Some (Adapt.address_to_string client_address);
    severity = `Warning;
    will_send_response = false;
  } in

  Lwt.async (fun () ->
    double_faults
      (fun () -> Lwt.map ignore (user's_error_handler error))
      Lwt.return)



let websocket
    user's_error_handler request response =
    fun socket error ->

  (* Note: in this function, request and response are from the original request
     that negotiated the websocket. *)

  Httpun_ws.Wsd.close socket;

  (* The only constructor of error is `Exn, so presumably these are server-side
     errors. Not sure if any I/O errors are possible here. *)
  let `Exn exn = error in

  let error = {
    Catch.condition = `Exn exn;
    layer = `WebSocket;
    caused_by = `Server;
    request = Some request;
    response = Some response;
    client = Some (Helpers.client request);
    severity = `Warning;   (* Not sure what these errors are, yet. *)
    will_send_response = false;
  } in

  Lwt.async (fun () ->
    double_faults
      (fun () -> Lwt.map ignore (user's_error_handler error))
      Lwt.return)



let websocket_handshake
    user's_error_handler =
    fun request response error_string ->

  let error = {
    Catch.condition = `String error_string;
    layer = `WebSocket;
    caused_by = `Client;
    request = Some request;
    response = Some response;
    client = Some (Helpers.client request);
    severity = `Warning;
    will_send_response = true;
  } in

  respond_with_option (fun () -> user's_error_handler error)
