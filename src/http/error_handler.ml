(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* TODO DOC The error handler is almost a middleware. But it needs to plug in to
   the lower levels of the framework. Also, a benefit of it not being directly
   a middleware is that it cannot wrongly appear composed into deeper levels of
   an app. *)

let log =
  Dream__middleware.Log.sub_log "dream.http"

let select_log = function
  | `Error -> log.error
  | `Warning -> log.warning
  | `Info -> log.info
  | `Debug -> log.debug



let dump (error : Error.error) =
  let buffer = Buffer.create 4096 in
  let p format = Printf.bprintf buffer format in

  begin match error.condition, error.response with
  | `Response, Some response ->
    let status = Dream.status response in
    p "%i %s\n" (Dream.status_to_int status) (Dream.status_to_string status)

  | `Response, None ->
    p "(Internal error: error response, but the response is missing!)\n"

  | `String "", _ ->
    p "(Library error without description payload)\n"

  | `String string, _ ->
    p "%s\n" string

  | `Exn exn, _ ->
    p "%s\n" (Printexc.to_string exn);
    Printexc.get_backtrace ()
    |> Dream__middleware.Log.iter_backtrace (p "%s\n")
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
    let last = Dream.last request in

    let major, minor = Dream.version last in
    p "\n\n%s %s HTTP/%i.%i"
      (Dream.method_to_string (Dream.method_ last))
      (Dream.target last)
      major minor;

    Dream.all_headers last
    |> List.iter (fun (name, value) -> p "\n%s: %s" name value);

    let show_variables kind =
      kind (fun name value first ->
        if first then
          p "\n";
        p "\n%s: %s" name value;
        false)
        true
        request
      |> ignore
    in
    show_variables Dream.fold_locals;
    show_variables Dream.fold_globals
  end;

  Buffer.contents buffer

(* TODO LATER Some library is registering S-exp-based printers for expressions,
   which are calling functions that use exceptions during parsing, which are
   clobbering the backtrace. *)
let customize template (error : Error.error) =

  (* First, log the error. *)

  begin match error.condition with
  | `Response -> ()
  | `String _ | `Exn _ as condition ->

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
      | `Exn exn -> Printexc.to_string exn, Printexc.get_backtrace ()
    in

    let message = String.concat ": " (layer @ [description]) in

    select_log error.severity (fun log ->
      log ?request:error.request "%s" message);
    backtrace |> Dream__middleware.Log.iter_backtrace (fun line ->
      select_log error.severity (fun log ->
        log ?request:error.request "%s" line))
  end;

  (* If Dream will not send a response for this error, we are done after
     logging. Otherwise, if debugging is enabled, gather a bunch of information.
     Then, call the template, and return the response. *)

  if not error.will_send_response then
    Lwt.return_none

  else
    let debug_info =
      match error.debug with
      | false -> None
      | true -> Some (dump error)
    in

    let response =
      match error.condition, error.response with
      | `Response, Some response -> response
      | _ ->
        let status =
          match error.caused_by with
          | `Server -> `Internal_server_error
          | `Client -> `Bad_request
        in
        Dream.response ~status ""
    in

    (* No need to catch errors when calling the template, because every call
       site of the error handler already has error handlers for catching double
       faults. *)
    response
    |> template ~debug_info
    |> Lwt.map (fun response -> Some response)



(* TODO LATER Make a nice default template. *)
let default_template ~debug_info response =
  let response =
    match debug_info with
    | None -> response
    | Some info ->
      response
      |> Dream.with_body info
      |> Dream.with_header "Content-Type" "text/plain"
  in

  Lwt.return response



let default =
  customize default_template



(* Error reporters (called in various places by the framework). *)



let double_faults f default =
  Lwt.catch f begin fun exn ->
    log.error (fun log ->
      log "Error handler raised: %s" (Printexc.to_string exn));

    Printexc.get_backtrace ()
    |> Dream__middleware.Log.iter_backtrace (fun line ->
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
        | None -> Dream.response ~status:`Internal_server_error ""))
    (fun () ->
      Dream.respond ~status:`Internal_server_error "")



(* In the functions below, the first row or set of arguments comes from the
   framework, by partial application, and the second row or set (after "fun")
   comes from the state machine (http/af, h2, websocket/af, ocaml-tls, etc.) *)

(* This error handler actually *is* a middleware, but it is just one pathway for
   reaching the centralized error handler provided by the user, so it is built
   into the framework. *)

let app
    app user's_error_handler =
    fun next_handler request ->

  Lwt.try_bind

    (fun () ->
      next_handler request)

    (fun response ->
      let status = Dream.status response in

      if Dream.is_client_error status || Dream.is_server_error status then begin
        let caused_by, severity =
          if Dream.is_client_error status then
            `Client, `Warning
          else
            `Server, `Error
        in

        let error = Error.{
          condition = `Response;
          layer = `App;
          caused_by;
          request = Some request;
          response = Some response;
          client = Some (Dream.client request);
          severity = severity;
          debug = Dream.debug app;
          will_send_response = true;
        } in

        respond_with_option (fun () -> user's_error_handler error)
      end
      else
        Lwt.return response)

    (* This exception handler is partially redundant, in that the HTTP-level
       handlers will also catch exceptions. However, this handler is able to
       capture more relevant context. We leave the HTTP-level handlers for truly
       severe protocol-level errors and integration mistakes. *)
    (fun exn ->
      let error = Error.{
        condition = `Exn exn;
        layer = `App;
        caused_by = `Server;
        request = Some request;
        response = None;
        client = Some (Dream.client request);
        severity = `Error;
        debug = Dream.debug app;
        will_send_response = true;
      } in

      respond_with_option (fun () -> user's_error_handler error))



let default_response = function
  | `Server -> Dream.response ~status:`Internal_server_error ""
  | `Client -> Dream.response ~status:`Bad_request ""

let httpaf
    app user's_error_handler =
    fun client_address ?request error start_response ->

  ignore (request : Httpaf.Request.t option);
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

  let error = Error.{
    condition;
    layer = `HTTP;
    caused_by;
    request = None;
    response = None;
    client = Some (Adapt.address_to_string client_address);
    severity;
    debug = Dream.debug app;
    will_send_response = true;
  } in

  Lwt.async begin fun () ->
    double_faults begin fun () ->
      let open Lwt.Infix in

      user's_error_handler error
      >>= fun response ->

      let response =
        match response with
        | Some response -> response
        | None -> default_response caused_by
      in

      let headers = Httpaf.Headers.of_list (Dream.all_headers response) in
      let body = start_response headers in

      Adapt.forward_body response body;

      Lwt.return_unit
    end
      Lwt.return
  end



let h2
    app user's_error_handler =
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

  let error = Error.{
    condition;
    layer = `HTTP2;
    caused_by;
    request = None;
    response = None;
    client = Some (Adapt.address_to_string client_address);
    severity;
    debug = Dream.debug app;
    will_send_response = true;
  } in

  Lwt.async begin fun () ->
    double_faults begin fun () ->
      let open Lwt.Infix in

      user's_error_handler error
      >>= fun response ->

      let response =
        match response with
        | Some response -> response
        | None -> default_response caused_by
      in

      let headers = H2.Headers.of_list (Dream.all_headers response) in
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
    app user's_error_handler client_address error =

  let error = Error.{
    condition = `Exn error;
    layer = `TLS;
    caused_by = `Client;
    request = None;
    response = None;
    client = Some (Adapt.address_to_string client_address);
    severity = `Warning;
    debug = Dream.debug app;
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

  Websocketaf.Wsd.close socket;

  (* The only constructor of error is `Exn, so presumably these are server-side
     errors. Not sure if any I/O errors are possible here. *)
  let `Exn exn = error in

  let error = Error.{
    condition = `Exn exn;
    layer = `WebSocket;
    caused_by = `Server;
    request = Some request;
    response = Some response;
    client = Some (Dream.client request);
    severity = `Warning;   (* Not sure what these errors are, yet. *)
    debug = Dream.debug (Dream.app request);
    will_send_response = false;
  } in

  Lwt.async (fun () ->
    double_faults
      (fun () -> Lwt.map ignore (user's_error_handler error))
      Lwt.return)



let websocket_handshake
    user's_error_handler =
    fun request response error_string ->

  let error = Error.{
    condition = `String error_string;
    layer = `WebSocket;
    caused_by = `Client;
    request = Some request;
    response = Some response;
    client = Some (Dream.client request);
    severity = `Warning;
    debug = Dream.debug (Dream.app request);
    will_send_response = true;
  } in

  respond_with_option (fun () -> user's_error_handler error)
