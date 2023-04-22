(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)


open Eio.Std

module Gluten = Dream_gluten.Gluten
module Gluten_eio = Dream_gluten_eio.Gluten_eio
module Httpaf = Dream_httpaf_.Httpaf
module Httpaf_eio = Dream_httpaf__eio.Httpaf_eio
module H2 = Dream_h2.H2
module H2_eio = Dream_h2_eio.H2_eio
module Websocketaf = Dream_websocketaf.Websocketaf

module Catch = Dream__server.Catch
module Helpers = Dream__server.Helpers
module Log = Dream__server.Log
module Message = Dream_pure.Message
module Method = Dream_pure.Method
module Random = Dream__cipher.Random
module Status = Dream_pure.Status
module Stream = Dream_pure.Stream



(* TODO In serious need of refactoring because of all the different handlers. *)



let to_dream_method method_ =
  Httpaf.Method.to_string method_ |> Method.string_to_method

let to_httpaf_status status =
  Status.status_to_int status |> Httpaf.Status.of_code

let to_h2_status status =
  Status.status_to_int status |> H2.Status.of_code

let sha1 s =
  s
  |> Digestif.SHA1.digest_string
  |> Digestif.SHA1.to_raw_string

let websocket_log =
  Log.sub_log "dream.websocket"



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
    tls
    (user's_error_handler : Catch.error_handler)
    (user's_dream_handler : Message.handler) =

  let httpaf_request_handler = fun client_address (conn : _ Gluten.Reqd.t) ->
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
    let headers =
      Httpaf.Headers.to_list httpaf_request.headers in

    let body =
      Httpaf.Reqd.request_body conn in
    (* TODO Review per-chunk allocations. *)
    (* TODO Should the stream be auto-closed? It doesn't even have a closed
       state. The whole thing is just a wrapper for whatever the http/af
       behavior is. *)
    let read ~data ~flush:_ ~ping:_ ~pong:_ ~close ~exn:_ =
      Httpaf.Body.Reader.schedule_read
        body
        ~on_eof:(fun () -> close 1000)
        ~on_read:(fun buffer ~off ~len -> data buffer off len true false)
    in
    let close _code =
      Httpaf.Body.Reader.close body in
    let body =
      Stream.reader ~read ~close ~abort:close in
    let body =
      Stream.stream body Stream.no_writer in

    let request : Message.request =
      Helpers.request ~client ~method_ ~target ~tls ~headers body in

    (* Call the user's handler. If it raises an exception or returns a promise
       that rejects with an exception, pass the exception up to Httpaf. This
       will cause it to call its (low-level) error handler with variand `Exn _.
       A well-behaved Dream app should catch all of its own exceptions and
       rejections in one of its top-level middlewares.

       We don't try to log exceptions here because the behavior is not
       customizable here. The handler itself is customizable (to catch all)
       exceptions, and the error callback that gets leaked exceptions is also
       customizable. *)
    begin
      try
        (* Do the big call. *)
        let response = user's_dream_handler request in

        (* Extract the Dream response's headers. *)

        (* This is the default function that translates the Dream response to an
           http/af response and sends it. We pre-define the function, however,
           because it is called from two places:

           1. Upon a normal response, the function is called unconditionally.
           2. Upon failure to establish a WebSocket, the function is called to
              transmit the resulting error response. *)
        let forward_response response =
          Message.set_content_length_headers response;

          let headers =
            Httpaf.Headers.of_list (Message.all_headers response) in

          let status =
            to_httpaf_status (Message.status response) in

          let httpaf_response =
            Httpaf.Response.create ~headers status in
          let body =
            Httpaf.Reqd.respond_with_streaming conn httpaf_response in

          Adapt.forward_body response body
        in

        match Message.get_websocket response with
        | None ->
          forward_response response
        | Some (client_stream, _server_stream) ->
          let error_handler =
            Error_handler.websocket user's_error_handler request response in

          let proceed () =
            Websocketaf.Server_connection.create_websocket
              ~error_handler
              (Dream_httpaf.Websocket.websocket_handler client_stream)
            |> Gluten.make (module Websocketaf.Server_connection)
            |> upgrade
          in

          let headers =
            Httpaf.Headers.of_list (Message.all_headers response) in

          Websocketaf.Handshake.respond_with_upgrade ~headers ~sha1 conn proceed
          |> function
          | Ok () -> ()
          | Error error_string ->
            let response =
              Error_handler.websocket_handshake
                user's_error_handler request response error_string
            in
            forward_response response
      with exn ->
        (* TODO There was something in the fork changelogs about not requiring
           report exn. Is it relevant to this? *)
        Httpaf.Reqd.report_exn conn exn
    end
  in

  httpaf_request_handler



(* TODO Factor out what is in common between the http/af and h2 handlers. *)
let wrap_handler_h2
    tls
    (_user's_error_handler : Catch.error_handler)
    (user's_dream_handler : Message.handler) =

  let httpaf_request_handler = fun client_address (conn : H2.Reqd.t) ->
    (* Covert the h2 request to a Dream request. *)
    let httpaf_request : H2.Request.t =
      H2.Reqd.request conn in

    let client =
      Adapt.address_to_string client_address in
    let method_ =
      to_dream_method httpaf_request.meth in
    let target =
      httpaf_request.target in
    let headers =
      H2.Headers.to_list httpaf_request.headers in

    let body =
      H2.Reqd.request_body conn in
    let read ~data ~flush:_ ~ping:_ ~pong:_ ~close ~exn:_ =
      H2.Body.Reader.schedule_read
        body
        ~on_eof:(fun () -> close 1000)
        ~on_read:(fun buffer ~off ~len -> data buffer off len true false)
    in
    let close _code =
      H2.Body.Reader.close body in
    let body =
      Stream.reader ~read ~close ~abort:close in
    let body =
      Stream.stream body Stream.no_writer in

    let request : Message.request =
      Helpers.request ~client ~method_ ~target ~tls ~headers body in

    (* Call the user's handler. If it raises an exception or returns a promise
       that rejects with an exception, pass the exception up to Httpaf. This
       will cause it to call its (low-level) error handler with variand `Exn _.
       A well-behaved Dream app should catch all of its own exceptions and
       rejections in one of its top-level middlewares.

       We don't try to log exceptions here because the behavior is not
       customizable here. The handler itself is customizable (to catch all)
       exceptions, and the error callback that gets leaked exceptions is also
       customizable. *)
    begin
      try
        (* Do the big call. *)
        let response = user's_dream_handler request in

        (* Extract the Dream response's headers. *)

        let forward_response response =
          Message.drop_content_length_headers response;
          Message.lowercase_headers response;
          let headers =
            H2.Headers.of_list (Message.all_headers response) in
          let status =
            to_h2_status (Message.status response) in
          let h2_response =
            H2.Response.create ~headers status in
          let body =
            H2.Reqd.respond_with_streaming conn h2_response in

          Adapt.forward_body_h2 response body
        in

        match Message.get_websocket response with
        | None ->
          forward_response response
        | Some _ ->
          (* TODO DOC H2 appears not to support WebSocket upgrade at present.
             RFC 8441. *)
          (* TODO DOC Do we need a CONNECT method? Do users need to be informed of
             this? *)
          ()
      with exn ->
        (* TODO LATER There was something in the fork changelogs about not
           requiring report_exn. Is it relevant to this? *)
        H2.Reqd.report_exn conn exn
    end
  in

  httpaf_request_handler



let log =
  Error_handler.log



type tls_library = {
  create_handler :
    certificate_file:string ->
    key_file:string ->
    handler:Message.handler ->
    error_handler:Catch.error_handler ->
    Eio.Net.Sockaddr.stream ->
    Eio.Flow.two_way ->
    unit;
}

let no_tls = {
  create_handler = begin fun
      ~certificate_file:_ ~key_file:_
      ~handler
      ~error_handler
      sockaddr
      fd ->
      Httpaf_eio.Server.create_connection_handler
        ?config:None
        ~request_handler:(wrap_handler false error_handler handler)
        ~error_handler:(Error_handler.httpaf error_handler)
        sockaddr
        fd
  end;
}

(*
let openssl = {
  create_handler = begin fun
      ~certificate_file ~key_file
      ~handler
      ~error_handler
      ~sw ->

    let httpaf_handler sockaddr socket =
      Httpaf_lwt_unix.Server.SSL.create_connection_handler
        ?config:None
      ~request_handler:(wrap_handler ~sw true error_handler handler)
      ~error_handler:(Error_handler.httpaf error_handler)
      sockaddr socket
      |> Lwt_eio.Promise.await_lwt
    in

    let h2_handler sockaddr socket =
      H2_lwt_unix.Server.SSL.create_connection_handler
        ?config:None
      ~request_handler:(wrap_handler_h2 ~sw true error_handler handler)
      ~error_handler:(Error_handler.h2 error_handler)
      sockaddr socket
      |> Lwt_eio.Promise.await_lwt
    in

    let perform_tls_handshake =
      Gluten_lwt_unix.Server.SSL.create_default
        ~alpn_protocols:["h2"; "http/1.1"]
        ~certfile:certificate_file
        ~keyfile:key_file
    in

    fun client_address unix_socket ->
      let tls_endpoint = Lwt_eio.Promise.await_lwt @@ perform_tls_handshake client_address unix_socket in
      (* TODO LATER This part with getting the negotiated protocol belongs in
         Gluten. Right now, we've picked up a hard dep on OpenSSL. *)
      (* See also https://github.com/anmonteiro/ocaml-h2/blob/66d92f1694b488ea638aa5073c796e164d5fbd9e/examples/alpn/unix/alpn_server_ssl.ml#L57 *)
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
      ~handler
      ~error_handler
      ~sw
      sockaddr
      fd ->
      Lwt_eio.Promise.await_lwt @@
    Httpaf_lwt_unix.Server.TLS.create_connection_handler_with_default
      ~certfile:certificate_file ~keyfile:key_file
      ?config:None
      ~request_handler:(wrap_handler ~sw true error_handler handler)
      ~error_handler:(Error_handler.httpaf error_handler)
      sockaddr
      fd
}
*)



let built_in_middleware error_handler =
  Message.pipeline [
    Catch.catch (Error_handler.app error_handler);
  ]



let of_unix_addr = function
  | Unix.ADDR_INET (host, port) -> `Tcp (Eio_unix.Ipaddr.of_unix host, port)
  | Unix.ADDR_UNIX path -> `Unix path

let to_unix_addr = function
  | `Tcp (host, port) -> Unix.ADDR_INET (Eio_unix.Ipaddr.to_unix host, port)
  | `Unix path -> Unix.ADDR_UNIX path



let serve_with_details
    caller_function_for_error_messages
    tls_library
    ~net
    ~interface
    ~port
    ?stop
    ~error_handler
    ~backlog
    ~certificate_file
    ~key_file
    ~builtins
    user's_dream_handler =

  (* TODO DOC *)
  (* https://letsencrypt.org/docs/certificates-for-localhost/ *)

  let user's_dream_handler =
    if builtins then
      built_in_middleware error_handler user's_dream_handler
    else
      user's_dream_handler
  in

  (* Create the wrapped httpaf or h2 handler from the user's Dream handler. *)
  let httpaf_connection_handler =
    tls_library.create_handler
      ~certificate_file
      ~key_file
      ~handler:user's_dream_handler
      ~error_handler
  in

  (* TODO Should probably move out to the TLS library options. *)
  let tls_error_handler = Error_handler.tls error_handler in

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
  let httpaf_connection_handler flow client_address =
    try
      httpaf_connection_handler client_address flow
    with exn ->
      tls_error_handler client_address exn
  in

  let listen_address =
    (* Look up the low-level address corresponding to the interface. Hopefully,
       this is a local interface. *)
    let addresses = Unix.getaddrinfo interface (string_of_int port) [] in
    match addresses with
    | [] ->
      Printf.ksprintf failwith "Dream.%s: no interface with address %s"
        caller_function_for_error_messages interface
    | address::_ ->
      of_unix_addr address.ai_addr
  in

  (* Bring up the HTTP server. *)
  Switch.run @@ fun sw ->
  let socket =
    Eio.Net.listen ~sw net listen_address
      ~reuse_addr:true
      ~backlog
  in
  Eio.Net.run_server ?stop socket httpaf_connection_handler ~on_error:raise



let is_localhost interface =
  interface = "localhost" || interface = "127.0.0.1"

let serve_with_maybe_https
    caller_function_for_error_messages
    ~interface
    ~port
    ?stop
    ~error_handler
    ~backlog
    ~tls
    ?certificate_file ?key_file
    ?certificate_string ?key_string
    ~builtins
    ~net
    user's_dream_handler =
  ignore certificate_file;
  ignore key_file;
  ignore certificate_string;
  ignore key_string;

  try
    (* This check will at least catch secrets like "foo" when used on a public
       interface. *)
    (* if not (is_localhost interface) then
      if String.length secret < 32 then begin
        log.warning (fun log -> log "Using a short key on a public interface");
        log.warning (fun log ->
          log "Consider using Dream.to_base64url (Dream.random 32)");
    end; *)
    (* TODO Make sure there is a similar check in cipher.ml now.Hpack *)

    match tls with
    | `No ->
      serve_with_details
        caller_function_for_error_messages
        no_tls
        ~net
        ~interface
        ~port
        ?stop
        ~error_handler
        ~backlog
        ~certificate_file:""
        ~key_file:""
        ~builtins
        user's_dream_handler

(*
    | `OpenSSL | `OCaml_TLS as tls_library ->
      (* TODO Writing temporary files is extremely questionable for anything
         except the fake localhost certificate. This needs loud warnings. IIRC
         the SSL binding already supports in-memory certificates. Does TLS? In
         any case, this would need upstream work. *)
      let certificate_and_key =
        match certificate_file, key_file, certificate_string, key_string with
        | None, None, None, None ->
          (* Use the built-in development certificate. However, if the interface
            is not a loopback interface, write a warning. *)
          if not (is_localhost interface) then begin
            log.warning (fun log ->
              log "Using a development SSL certificate on a public interface");
            log.warning (fun log ->
              log "See arguments ~certificate_file and ~key_file");
          end;

          `Memory (
            Dream__certificate.localhost_certificate,
            Dream__certificate.localhost_certificate_key,
            `Silent
          )

        | Some certificate_file, Some key_file, None, None ->
          `File (certificate_file, key_file)

        | None, None, Some certificate_string, Some key_string ->
          (* This is likely a non-development in-memory certificate, and it
             seems reasonable to warn that we are going to write it to a
             temporary file, with security implications. *)
          log.warning (fun log ->
            log "In-memory certificates will be written to temporary files");

          (* Show where the certificate is written so that the user can get rid
             of it, if necessary. In particular, the key file should be removed
             using srm. This whole scheme is just completely insecure, because
             the server itself does not use an equivalent of srm to get rid of
             the temporary file. Updstream support is really necessary here. *)
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
          ~net
          ~interface
          ~port
          ~error_handler
          ~certificate_file
          ~key_file
          ~builtins
          user's_dream_handler

      | `Memory (certificate_string, key_string, verbose_or_silent) ->
        Lwt_eio.Promise.await_lwt @@
        Lwt_io.with_temp_file begin fun (certificate_file, certificate_stream) ->
        Lwt_io.with_temp_file begin fun (key_file, key_stream) ->

        if verbose_or_silent <> `Silent then begin
          log.warning (fun log ->
            log "Writing certificate to %s" certificate_file);
          log.warning (fun log ->
            log "Writing key to %s" key_file);
        end;

        let%lwt () = Lwt_io.write certificate_stream certificate_string in
        let%lwt () = Lwt_io.write key_stream key_string in
        let%lwt () = Lwt_io.close certificate_stream in
        let%lwt () = Lwt_io.close key_stream in

        Lwt_eio.run_eio @@ fun () ->
        serve_with_details
          caller_function_for_error_messages
          tls_library
          ~interface
          ~port
          ~error_handler
          ~certificate_file
          ~key_file
          ~builtins
          ~net
          user's_dream_handler

        end
        end
  *)

  with exn ->
    let backtrace = Printexc.get_backtrace () in
    log.error (fun log ->
      log "Dream.%s: exception %s"
        caller_function_for_error_messages (Printexc.to_string exn));
    backtrace |> Log.iter_backtrace (fun line ->
      log.error (fun log -> log "%s" line));
    raise exn



let default_interface = "localhost"
let default_port = 8080



let serve
    ?(interface = default_interface)
    ?(port = default_port)
    ?stop
    ?(error_handler = Error_handler.default)
    ?(backlog = 10)
    ?(tls = false)
    ?certificate_file
    ?key_file
    ?(builtins = true)
    ~net
    user's_dream_handler =
  ignore tls;

  serve_with_maybe_https
    "serve"
    ~net
    ~interface
    ~port
    ?stop
    ~error_handler
    ~backlog
    (* ~tls:(if tls then `OpenSSL else `No) *)
    ~tls:`No
    ?certificate_file
    ?key_file
    ?certificate_string:None
    ?key_string:None
    ~builtins
    user's_dream_handler



let run
    ?(interface = default_interface)
    ?(port = default_port)
    ?stop
    ?(error_handler = Error_handler.default)
    ?(backlog = 10)
    ?(tls = false)
    ?certificate_file
    ?key_file
    ?(builtins = true)
    ?(greeting = true)
    ?(adjust_terminal = true)
    env
    user's_dream_handler =
  Random.run env @@ fun () ->

  let () = if Sys.unix then
    Sys.(set_signal sigpipe Signal_ignore)
  in

  let adjust_terminal =
    adjust_terminal && Sys.os_type <> "Win32" && Unix.(isatty stderr) in

  let restore_terminal =
    if adjust_terminal then begin
      (* The mystery terminal escape sequence is $(tput rmam). Prefer this,
         hopefully it is portable enough. Calling tput seems like a security
         risk, and I am not aware of an API for doing this programmatically. *)
      prerr_string "\x1b[?7l";
      flush stderr;
      let attributes = Unix.(tcgetattr stderr) in
      attributes.c_echo <- false;
      Unix.(tcsetattr stderr TCSANOW) attributes;
      fun () ->
        (* The escape sequence is $(tput smam). *)
        prerr_string "\x1b[?7h";
        flush stderr
    end
    else
      ignore
  in

  let create_handler signal =
    let previous_signal_behavior = ref Sys.Signal_default in
    previous_signal_behavior :=
      Sys.signal signal @@ Sys.Signal_handle (fun signal ->
        restore_terminal ();
        match !previous_signal_behavior with
        | Sys.Signal_handle f -> f signal
        | Sys.Signal_ignore -> ignore ()
        | Sys.Signal_default ->
          Sys.set_signal signal Sys.Signal_default;
          Unix.kill (Unix.getpid ()) signal)
  in

  create_handler Sys.sigint;
  create_handler Sys.sigterm;

  let log = Log.convenience_log in

  if greeting then begin
    let scheme =
      if tls then
        "https"
      else
        "http"
    in

    begin match interface with
    | "localhost" | "127.0.0.1" ->
      log "Running at %s://localhost:%i" scheme port
    | _ ->
      log "Running on %s:%i (%s://localhost:%i)" interface port scheme port
    end;
    log "Type Ctrl+C to stop"
  end;

  try
    begin
      serve_with_maybe_https
        "run"
        ~net:env#net
        ~interface
        ~port
        ?stop
        ~error_handler
        ~backlog
        (* ~tls:(if tls then `OpenSSL else `No) *)
        ~tls:`No
        ?certificate_file ?key_file
        ?certificate_string:None ?key_string:None
        ~builtins
        user's_dream_handler
    end;
    restore_terminal ()

  with exn ->
    restore_terminal ();
    raise exn
