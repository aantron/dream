(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost
module Error = Dream__middleware.Error



(* TODO DOC https://http2-explained.haxx.se/en
https://http2-explained.haxx.se/en/part6
- Stream priorities.
- Header compression options.
- Stream reset.
- Push.
- Flow control.

- https://github.com/httpwg/http2-spec/wiki/Implementations
- BREACH safety?
- https://github.com/anmonteiro/ocaml-quic
 *)

(* TODO In serious need of refactoring because of all the different handlers. *)



let to_dream_method method_ =
  Httpaf.Method.to_string method_ |> Dream.string_to_method

let to_httpaf_status status =
  Dream.status_to_int status |> Httpaf.Status.of_code

let to_h2_status status =
  Dream.status_to_int status |> H2.Status.of_code

(* TODO Contact upstream: this is from websocketaf/lwt/websocketaf_lwt.ml, but
   it is not exposed. *)
let sha1 s =
  s
  |> Digestif.SHA1.digest_string
  |> Digestif.SHA1.to_raw_string



(* TODO DOC https://tools.ietf.org/html/rfc6455 *)
(* https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers *)
(* TODO Offer a "raw" mode that allows the client to stream frames without the
   intermediate buffer in which message reassembly occurs. *)
(* TODO It appears that backpressure is impossible in the underlying
   implementation... *)
let websocket_handler user's_websocket_handler socket =

  (* Frames of the current partial message, in reverse order. *)
  let message_frames = ref [] in

  (* Queue of received messages. There doesn't appear to be a nice way to
     achieve backpressure with the current API of websocketaf, so that will have
     to be added later. The user-facing API of Dream does support backpressure.
     It's just that this code here reads no matter whether there is a
     higher-level reader. *)
  let messages, push_message = Lwt_stream.create () in

  let send kind message =
    let kind = (kind :> [ `Text | `Binary | `Continuation ]) in
    Websocketaf.Wsd.send_bytes
      socket
      ~kind
      (Bytes.unsafe_of_string message)
      ~off:0
      ~len:(String.length message);
    Lwt.return_unit
  in

  let receive () =
    Lwt_stream.get messages in

  let close () =
    Websocketaf.Wsd.close socket;
    Lwt.return_unit
  in

  let websocket = {
    Dream.send;
    receive;
    close;
  } in

  (* TODO Needs error handling like the top-level app has! *)
  Lwt.async (fun () ->
    user's_websocket_handler websocket);

  (* The code isn't very efficient at the moment, doing multiple copies while
     assembling a message. However, multi-fragment messages should be relatively
     rare. *)

  (* This function is called on each frame received. In this high-level handler.
     we automatically respond to all control opcodes. *)
  let frame ~opcode ~is_fin buffer ~off ~len =
    match opcode with
    | `Connection_close ->
      Websocketaf.Wsd.close socket;
      push_message None;
    | `Ping ->
      Websocketaf.Wsd.send_pong socket
    | `Pong ->
      ()
    | `Other _ ->
      ()

    | `Text
    | `Binary ->
      let fragment = Lwt_bytes.to_string (Lwt_bytes.proxy buffer off len) in
      if is_fin then
        push_message (Some fragment)
      else
        message_frames := [fragment]

    | `Continuation ->
      let fragment = Lwt_bytes.to_string (Lwt_bytes.proxy buffer off len) in
      message_frames := fragment::!message_frames;
      if is_fin then begin
        let message = String.concat "" (List.rev !message_frames) in
        message_frames := [];
        push_message (Some message)
      end


    (* | `Continuation ->
      let open Lwt.Infix in
      (Lwt_bytes.proxy buffer off len
      |> Lwt_bytes.to_string
      |> user's_websocket_handler
      >>= fun response ->
      Websocketaf.Wsd.send_bytes
        socket
        ~kind:`Text
        (Bytes.unsafe_of_string response)
        ~off:0
        ~len:(String.length response);
      Lwt.return_unit)
      |> ignore *)
      (* TODO Need to send errors to the error handler, so these two handlers
         will have to be defined together. *)
  in

  let eof () =
    push_message None;
    Websocketaf.Wsd.close socket
  in

  Websocketaf.Server_connection.{frame; eof}


(* Wraps the user's Dream handler in the kind of handler expected by http/af.
   The scheme is simple: wait for http/af "Reqd.t"s (partially parsed
   connections), convert their fields to Dream.request, call the user's handler,
   wait for the Dream.response, and then convert it to an http/af Response and
   sned it.

   If the user's handler (wrongly) leaks any exceptions or rejections, they are
   passed to http/af to end up in the error handler. This is a low-level handler
   that ordinarily shouldn't be relied on by the user - this is just our last
   chance to tell the user that something is wrong with their app. *)
(* TODO Rename conn like in the body branch. *)
let wrap_handler
    app
    (user's_error_handler : Error.error_handler)
    (user's_dream_handler : Dream.handler) =

  let httpaf_request_handler = fun client_address (conn : _ Gluten.Reqd.t) ->
    Dream__middleware.Log.set_up_exception_hook ();

    let conn, upgrade = conn.reqd, conn.upgrade in

    (* Covert the http/af request to a Dream request. *)
    let httpaf_request : Httpaf.Request.t =
      Httpaf.Reqd.request conn in

    let client =
      Adapt.address_to_string client_address in
    let method_ =
      to_dream_method httpaf_request.meth in
    let target =
      httpaf_request.target in
    let version =
      (httpaf_request.version.major, httpaf_request.version.minor) in
    let headers =
      Httpaf.Headers.to_list httpaf_request.headers in

    let body =
      Httpaf.Reqd.request_body conn in
    let body =
      fun data eof ->
        Httpaf.Body.schedule_read
          body
          ~on_eof:eof
          ~on_read:(fun buffer ~off ~len -> data buffer off len)
          (* TODO Doesn't this allocate? *)
    in
      (* Httpaf.Body.schedule_read body
        ~on_eof:(fun () -> k None)
        ~on_read:(fun buffer ~off ~len ->
          k (Some (Bigarray_compat.Array1.sub buffer off len))) in *)

    let request : Dream.request =
      Dream.request_from_http
        ~app ~client ~method_ ~target ~version ~headers ~body in

    (* Call the user's handler. If it raises an exception or returns a promise
       that rejects with an exception, pass the exception up to Httpaf. This
       will cause it to call its (low-level) error handler with variand `Exn _.
       A well-behaved Dream app should catch all of its own exceptions and
       rejections in one of its top-level middlewares.

       We don't try to log exceptions here because the behavior is not
       customizable here. The handler itself is customizable (to catch all)
       exceptions, and the error callback that gets leaked exceptions is also
       customizable. *)
    Lwt.async begin fun () ->
      Lwt.catch begin fun () ->
        let open Lwt.Infix in

        (* Do the big call. *)
        user's_dream_handler request

        (* Extract the Dream response's headers. *)
        >>= fun (response : Dream.response) ->

        (* This is the default function that translates the Dream response to an
           http/af response and sends it. We pre-define the function, however,
           because it is called from two places:

           1. Upon a normal response, the function is called unconditionally.
           2. Upon failure to establish a WebSocket, the function is called to
              transmit the resulting error response. *)
        let forward_response response =
          let headers =
            Httpaf.Headers.of_list (Dream.all_headers response) in

          (* let version =
            match Dream.version_override response with
            | None -> None
            | Some (major, minor) -> Some Httpaf.Version.{major; minor}
          in *)
          let status =
            to_httpaf_status (Dream.status response) in
          (* let reason =
            Dream.reason_override response in *)

          let httpaf_response =
            Httpaf.Response.create ~headers status in
          let body =
            Httpaf.Reqd.respond_with_streaming conn httpaf_response in

          Adapt.forward_body response body;

          Lwt.return_unit
        in

        match Dream.is_websocket response with
        | None ->

          forward_response response

        | Some user's_websocket_handler ->

          let error_handler =
            Error_handler.websocket user's_error_handler request response in

          let proceed () =
            Websocketaf.Server_connection.create_websocket
              ~error_handler (websocket_handler user's_websocket_handler)
            |> Gluten.make (module Websocketaf.Server_connection)
            |> upgrade
          in

          let headers =
            Httpaf.Headers.of_list (Dream.all_headers response) in

          Websocketaf.Handshake.respond_with_upgrade ~headers ~sha1 conn proceed
          |> function
          | Ok () -> Lwt.return_unit
          | Error error_string ->
            Error_handler.websocket_handshake
              user's_error_handler request response error_string
            >>= forward_response

      end
      @@ fun exn ->
        (* TODO There was something in the fork changelogs about not requiring
           report exn. Is it relevant to this? *)
        Httpaf.Reqd.report_exn conn exn;
        Lwt.return_unit
    end
  in

  httpaf_request_handler



(* TODO Factor out what is in common between the http/af and h2 handlers. *)
let wrap_handler_h2
    app
    (_user's_error_handler : Error.error_handler)
    (user's_dream_handler : Dream.handler) =

  let httpaf_request_handler = fun client_address (conn : H2.Reqd.t) ->
    Dream__middleware.Log.set_up_exception_hook ();

    (* Covert the h2 request to a Dream request. *)
    let httpaf_request : H2.Request.t =
      H2.Reqd.request conn in

    let client =
      Adapt.address_to_string client_address in
    let method_ =
      to_dream_method httpaf_request.meth in
    let target =
      httpaf_request.target in
    let version =
      (2, 0) in
    let headers =
      H2.Headers.to_list httpaf_request.headers in

    let body =
      H2.Reqd.request_body conn in
    let body =
      fun data eof ->
        H2.Body.schedule_read
          body
          ~on_eof:eof
          ~on_read:(fun buffer ~off ~len -> data buffer off len)
    in

      (* H2.Body.schedule_read body
        ~on_eof:(fun () -> k None)
        ~on_read:(fun buffer ~off ~len ->
          k (Some (Bigarray_compat.Array1.sub buffer off len))) in *)

    let request : Dream.request =
      Dream.request_from_http
        ~app ~client ~method_ ~target ~version ~headers ~body in

    (* Call the user's handler. If it raises an exception or returns a promise
       that rejects with an exception, pass the exception up to Httpaf. This
       will cause it to call its (low-level) error handler with variand `Exn _.
       A well-behaved Dream app should catch all of its own exceptions and
       rejections in one of its top-level middlewares.

       We don't try to log exceptions here because the behavior is not
       customizable here. The handler itself is customizable (to catch all)
       exceptions, and the error callback that gets leaked exceptions is also
       customizable. *)
    Lwt.async begin fun () ->
      Lwt.catch begin fun () ->
        let open Lwt.Infix in

        (* Do the big call. *)
        user's_dream_handler request

        (* Extract the Dream response's headers. *)
        >>= fun (response : Dream.response) ->

        let forward_response response =
          let headers =
            H2.Headers.of_list (Dream.all_headers response) in
          let status =
            to_h2_status (Dream.status response) in
          let h2_response =
            H2.Response.create ~headers status in
          let body =
            H2.Reqd.respond_with_streaming conn h2_response in

          Adapt.forward_body_h2 response body;

          Lwt.return_unit
        in

        match Dream.is_websocket response with
        | None ->
          forward_response response

        (* TODO DOC H2 appears not to support WebSocket upgrade at present.
           RFC 8441. *)
        (* TODO DOC Do we need a CONNECT method? Do users need to be informed of
           this? *)
        | Some _user's_websocket_handler ->
          Lwt.return_unit

      end
      @@ fun exn ->
        (* TODO LATER There was something in the fork changelogs about not
           requiring report_exn. Is it relevant to this? *)
        H2.Reqd.report_exn conn exn;
        Lwt.return_unit
    end
  in

  httpaf_request_handler



let log =
  Error_handler.log



type tls_library = {
  create_handler :
    certificate_file:string ->
    key_file:string ->
    app:Dream.app ->
    handler:Dream.handler ->
    error_handler:Error.error_handler ->
      Unix.sockaddr ->
      Lwt_unix.file_descr ->
        unit Lwt.t;
}

let no_tls = {
  create_handler = begin fun
      ~certificate_file:_ ~key_file:_
      ~app
      ~handler
      ~error_handler ->
    Httpaf_lwt_unix.Server.create_connection_handler
      ?config:None
      ~request_handler:(wrap_handler app error_handler handler)
      ~error_handler:(Error_handler.httpaf app error_handler)
  end;
}

let openssl = {
  create_handler = begin fun
      ~certificate_file ~key_file
      ~app
      ~handler
      ~error_handler ->

    let httpaf_handler =
      Httpaf_lwt_unix.Server.SSL.create_connection_handler
        ?config:None
      ~request_handler:(wrap_handler app error_handler handler)
      ~error_handler:(Error_handler.httpaf app error_handler)
    in

    let h2_handler =
      H2_lwt_unix.Server.SSL.create_connection_handler
        ?config:None
      ~request_handler:(wrap_handler_h2 app error_handler handler)
      ~error_handler:(Error_handler.h2 app error_handler)
    in

    let perform_tls_handshake =
      Gluten_lwt_unix.Server.SSL.create_default
        ~alpn_protocols:["h2"; "http/1.1"]
        ~certfile:certificate_file
        ~keyfile:key_file
    in

    fun client_address unix_socket ->
      let open Lwt.Infix in
      perform_tls_handshake client_address unix_socket
      >>= fun tls_endpoint ->
      (* TODO LATER This part with getting the negotiated protocol belongs in
         Gluten. Right now, we've picked up a hard dep on OpenSSL. *)
      match Lwt_ssl.ssl_socket tls_endpoint with
      | None ->
        assert false
      | Some tls_socket ->
        match Ssl.get_negotiated_alpn_protocol tls_socket with
        | None ->
          (* Not 100% confirmed, but it appears that at least Chromium does not
             send an ALPN protocol list when attempting to establish a secure
             WebSocket connection (presumably, it assumes HTTP/1.1; RFC 8441 is
             not implemented). This is partially good, because h2 does not seem
             to implement RFC 8441, either. So, to support wss:// in the
             presence of ALPN, handle ALPN failure by just continuing with
             HTTP/1.1. Once there is HTTP/2 WebSocket support, the web
             application will need to respond to the CONNECT method. *)
          (* TODO DOC User guidance on responding to both GET and CONNECT in
             WebSocket handlers. *)
          httpaf_handler client_address tls_endpoint
        | Some "http/1.1" ->
          httpaf_handler client_address tls_endpoint
        | Some "h2" ->
          h2_handler client_address tls_endpoint
        | Some _ ->
          assert false
  end;
}

(* TODO LATER Add ALPN + HTTP/2.0 with ocaml-tls, too. *)
let ocaml_tls = {
  create_handler = fun
      ~certificate_file ~key_file
      ~app
      ~handler
      ~error_handler ->
    Httpaf_lwt_unix.Server.TLS.create_connection_handler_with_default
      ~certfile:certificate_file ~keyfile:key_file
      ?config:None
      ~request_handler:(wrap_handler app error_handler handler)
      ~error_handler:(Error_handler.httpaf app error_handler)
}



let built_in_middleware error_handler prefix =
  Dream.pipeline [
    Dream__middleware.Catch.catch (Error_handler.app error_handler);
    Dream__middleware.Request_id.assign_request_id;
    Dream__middleware.Site_prefix.chop_site_prefix prefix;
    Dream__middleware.Content_length.content_length;
  ]



let serve_with_details
    caller_function_for_error_messages
    tls_library
    ~interface
    ~port
    ~stop
    ~error_handler
    ~prefix
    ~app
    ~certificate_file
    ~key_file
    user's_dream_handler =

  (* TODO DOC *)
  (* https://letsencrypt.org/docs/certificates-for-localhost/ *)

  let user's_dream_handler =
    built_in_middleware error_handler prefix user's_dream_handler in

  (* Create the wrapped httpaf or h2 handler from the user's Dream handler. *)
  let httpaf_connection_handler =
    tls_library.create_handler
      ~certificate_file
      ~key_file
      ~app
      ~handler:user's_dream_handler
      ~error_handler
  in

  (* TODO Should probably move out to the TLS library options. *)
  let tls_error_handler = Error_handler.tls app error_handler in

  (* Some parts of the various HTTP servers that are under heavy development
     ( *cough* Gluten SSL/TLS at the moment) leak exceptions out of the
     top-level handler instead of passing them to the error handler that we
     specified above with ~error_handler. So, to work around that, we pass the
     errors manually. Since we don't even have request or response objects at
     this point, we simply ignore the Dream.response that the error handler
     generates. We call it for any logging that it may do, and to swallow the
     error. Otherwise, it will go to !Lwt.async_exception_hook. *)
  (* TODO SSL alerts follow this pathway into the log at ERROR level, which is
     questionable - I understand that means clients can cause ERROR level log
     messages to be written into the log at will. To work around this, the
     exception should be formatted and passed as `Bad_request, or there should
     be pattern matching on the exception (but that might introduce dependency
     coupling), or the upstream should be patched to distinguish the errors in
     some useful way. *)
  let httpaf_connection_handler client_address socket =
    Lwt.catch
      (fun () ->
        httpaf_connection_handler client_address socket)
      (fun exn ->
        tls_error_handler client_address exn;
        Lwt.return_unit)
  in


  let open Lwt.Infix in

  (* Look up the low-level address corresponding to the interface. Hopefully,
     this is a local interface. *)
  Lwt_unix.getaddrinfo interface (string_of_int port) []
  >>= fun addresses ->
  match addresses with
  | [] ->
    Printf.ksprintf failwith "Dream.%s: no interface with address %s"
      caller_function_for_error_messages interface
  | address::_ ->
  let listen_address = Lwt_unix.(address.ai_addr) in


  (* Bring up the HTTP server. Wait for the server to actually get started.
     Then, wait for the ~stop promise. If the ~stop promise ever resolves, stop
     the server. *)
  Lwt_io.establish_server_with_client_socket
    listen_address
    httpaf_connection_handler
  >>= fun server ->
  stop
  >>= fun () ->
  Lwt_io.shutdown_server server
  >>= fun () ->
  Lwt.return_unit



(* TODO Validate the prefix here. *)
let serve_with_maybe_https
    caller_function_for_error_messages
    ~interface
    ~port
    ~stop
    ?debug
    ~error_handler
    ?secret
    ~prefix
    ?(app = Dream.new_app ())
    ~https
    ?certificate_file ?key_file
    ?certificate_string ?key_string
    user's_dream_handler =

  begin match debug with
  | Some debug -> Dream.set_debug debug app;
  | None -> ()
  end;

  (* TODO The interface needs to allow not messing with the secret if an app is
     passed. *)
  (* TODO Key guidance https://security.stackexchange.com/a/146889 *)
  begin match secret with
  | Some secret -> Dream.set_secret secret app;
  | None -> Dream.set_secret (Dream__middleware.Random.random 32) app
  end;

  match https with
  | `No ->
    serve_with_details
      caller_function_for_error_messages
      no_tls
      ~interface
      ~port
      ~stop
      ~error_handler
      ~prefix
      ~app
      ~certificate_file:""
      ~key_file:""
      user's_dream_handler

  | `OpenSSL | `OCaml_TLS as tls_library ->
    (* TODO Writing temporary files is extremely questionable for anything
       except the fake localhost certificate. This needs loud warnings. IIRC the
       SSL binding already supports in-memory certificates. Does TLS? In any
       case, this would need upstream work. *)
    let certificate_and_key =
      match certificate_file, key_file, certificate_string, key_string with
      | None, None, None, None ->
        (* Use the built-in development certificate. However, if the interface
           is not a loopback interface, write a warning. *)
        if interface <> "localhost" && interface <> "127.0.0.1" then begin
          log.warning (fun log ->
            log "Using a development SSL certificate on a public interface");
        end;

        `Memory (Dream__localhost.certificate, Dream__localhost.key, `Silent)

      | Some certificate_file, Some key_file, None, None ->
        `File (certificate_file, key_file)

      | None, None, Some certificate_string, Some key_string ->
        (* This is likely a non-development in-memory certificate, and it seems
           reasonable to warn that we are going to write it to a temporary file,
           with security implications. *)
        log.warning (fun log ->
          log "In-memory certificates will be written to temporary files");

        (* Show where the certificate is written so that the user can get rid of
           it, if necessary. In particular, the key file should be removed using
           srm. This whole scheme is just completely insecure, because the
           server itself does not use an equivalent of srm to get rid of the
           temporary file. Updstream support is really necessary here. *)
        `Memory (certificate_string, key_string, `Verbose)

      | _ ->
        raise (Invalid_argument
          "Must specify exactly one pair of certificate and key")
    in

    let tls_library =
      match tls_library with
      | `OpenSSL -> openssl
      | `OCaml_TLS -> ocaml_tls
    in

    match certificate_and_key with
    | `File (certificate_file, key_file) ->
      serve_with_details
        caller_function_for_error_messages
        tls_library
        ~interface
        ~port
        ~stop
        ~error_handler
        ~prefix
        ~app
        ~certificate_file
        ~key_file
        user's_dream_handler

    | `Memory (certificate_string, key_string, verbose_or_silent) ->
      Lwt_io.with_temp_file begin fun (certificate_file, certificate_stream) ->
      Lwt_io.with_temp_file begin fun (key_file, key_stream) ->

      let open Lwt.Infix in

      if verbose_or_silent <> `Silent then begin
        log.warning (fun log ->
          log "Writing certificate to %s" certificate_file);
        log.warning (fun log ->
          log "Writing key to %s" key_file);
      end;

      Lwt_io.write certificate_stream certificate_string
      >>= fun () ->
      Lwt_io.write key_stream key_string
      >>= fun () ->
      Lwt_io.close certificate_stream
      >>= fun () ->
      Lwt_io.close key_stream
      >>= fun () ->

      serve_with_details
        caller_function_for_error_messages
        tls_library
        ~interface
        ~port
        ~stop
        ~error_handler
        ~prefix
        ~app
        ~certificate_file
        ~key_file
        user's_dream_handler

      end
      end



let default_interface = "localhost"
let default_port = 8080
let never = fst (Lwt.wait ())



let serve
    ?(interface = default_interface)
    ?(port = default_port)
    ?(stop = never)
    ?debug
    ?(error_handler = Error_handler.default)
    ?secret
    ?(prefix = "")
    ?(https = `No)
    ?certificate_file
    ?key_file
    ?certificate_string
    ?key_string
    user's_dream_handler =

  serve_with_maybe_https
    "serve"
    ~interface
    ~port
    ~stop
    ?debug
    ~error_handler
    ?secret
    ~prefix
    ?app:None
    ~https
    ?certificate_file
    ?key_file
    ?certificate_string
    ?key_string
    user's_dream_handler



let run
    ?(interface = default_interface)
    ?(port = default_port)
    ?(stop = never)
    ?debug
    ?(error_handler = Error_handler.default)
    ?secret
    ?(prefix = "")
    ?(https = `No)
    ?certificate_file
    ?key_file
    ?certificate_string
    ?key_string
    ?(greeting = true)
    ?(stop_on_input = true)
    ?(graceful_stop = true)
    user's_dream_handler =

  let log = Dream__middleware.Log.convenience_log in

  if greeting then begin
    let scheme =
      if https = `No then
        "http"
      else
        "https"
    in

    let hostname =
      match interface with
      | "localhost" | "127.0.0.1" | "0.0.0.0" -> "localhost"
      | interface -> interface
    in

    log "Running on %s://%s:%i" scheme hostname port;
    if stop_on_input then
      log "Press ENTER to stop"
  end;

  let stop =
    if stop_on_input then
      Lwt.choose [stop; Lwt.map ignore Lwt_io.(read_char stdin)]
    else
      stop
  in

  Lwt_main.run begin
    let open Lwt.Infix in

    serve_with_maybe_https
      "run"
      ~interface
      ~port
      ~stop
      ?debug
      ~error_handler
      ?secret
      ~prefix
      ?app:None
      ~https
      ?certificate_file ?key_file
      ?certificate_string ?key_string
      user's_dream_handler
    >>= fun () ->

    if not graceful_stop then
      Lwt.return_unit
    else begin
      log "Stopping; allowing 1 second for requests to finish";
      Lwt_unix.sleep 1.
    end
  end


(* TODO LATER Can Dune's watcher kill the server? Just need SIGINT issued. *)
(* TODO LATER Project homepage to greeting message. *)
(* TODO LATER Terminal options docs, etc., log viewers, for line wrapping. *)
(* TODO DOC Gradual replacement of run by serve. *)
