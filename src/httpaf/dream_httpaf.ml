(* TODO Request contexts. *)
(* TODO Application contexts. *)

(* Wraps the user's Dream handler in the kind of handler expected by http/af.
   The scheme is simple: wait for http/af "Reqd.t"s (partially parsed
   connections), convert their fields to Dream.request, call the user's handler,
   wait for the Dream.response, and then convert it to an http/af Response and
   sned it.

   If the user's handler (wrongly) leaks any exceptions or rejections, they are
   passed to http/af to end up in the error handler. This is a low-level handler
   that ordinarily shouldn't be relied on by the user - this is just our last
   chance to tell the user that something is wrong with their app. *)
let wrap_handler (user's_dream_handler : Dream.handler) =

  (* One Dream application context for all the requests. *)
  let app =
    Dream.new_app () in

  let httpaf_request_handler = fun client_address (conn : Httpaf.Reqd.t) ->

    (* Covert the http/af request to a Dream request. *)
    let httpaf_request : Httpaf.Request.t =
      Httpaf.Reqd.request conn in

    let client =
      match (client_address : Unix.sockaddr) with
      | ADDR_UNIX path -> path
      | ADDR_INET (address, port) ->
        Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port
    in

    let method_ =
      httpaf_request.meth in
    let target =
      httpaf_request.target in
    let version =
      (httpaf_request.version.major, httpaf_request.version.minor) in
    let headers =
      Httpaf.Headers.to_list httpaf_request.headers in

    let request : Dream.request =
      Dream.internal_create_request
        ~app ~client ~method_ ~target ~version ~headers [@ocaml.warning "-3"]
    in

    (* TODO Stream request and response bodies. *)

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

        let status =
          (Dream.status response :> Httpaf.Status.t) in
        let headers =
          Httpaf.Headers.of_list (Dream.headers response) in

        let httpaf_response =
          Httpaf.Response.create ~headers status in

        Httpaf.Reqd.respond_with_string conn httpaf_response "";

        Lwt.return_unit
      end
      @@ fun exn ->
        Httpaf.Reqd.report_exn conn exn;
        Lwt.return_unit

    end

  in

  httpaf_request_handler


(* TODO Just log framework exceptions somewhere. Probably here, so we can also
   log bad requests. *)



type error_handler =
  Unix.sockaddr ->
  [ `Bad_request | `Bad_gateway | `Internal_server_error | `Exn of exn ] ->
    Dream.response Lwt.t

(* TODO Log errors. *)
let default_error_handler _client_address _error =
  (* TODO But do set the Content-length to 0. *)
  Lwt.return @@ Dream.response ()



let wrap_error_handler (user's_error_handler : error_handler) =
  let open Lwt.Infix in

  let httpaf_error_handler = fun client_address ?request error start_response ->
    ignore request;
    (* TODO In case of exception or rejection in the error handler, don't do
       anything. *)

    Lwt.async begin fun () ->
      user's_error_handler client_address error
      >>= fun _response ->
      (* TODO Take the headers and body from the actual response. *)
      let response_body = start_response Httpaf.Headers.empty in
      Httpaf.Body.write_string response_body "";
      Lwt.return_unit
    end
  in

  httpaf_error_handler



let serve =
  let never = fst (Lwt.wait ()) in

  fun
    ?(interface = "localhost") ?(port = 8080) ?(stop = never)
    ?(error_handler = default_error_handler)
    user's_dream_handler ->

  (* Create the wrapped Httpaf handler from the user's Dream handler. *)
  let httpaf_connection_handler =
    Httpaf_lwt_unix.Server.create_connection_handler
      ~request_handler:(wrap_handler user's_dream_handler)
      ~error_handler:(wrap_error_handler error_handler)
  in


  let open Lwt.Infix in

  (* Look up the low-level address corresponding to the interface. Hopefully,
     this is a local interface. *)
  Lwt_unix.getaddrinfo interface (string_of_int port) []
  >>= fun addresses ->
  match addresses with
  | [] ->
    (* TODO Also log here once there is a working logger. *)
    Printf.ksprintf failwith "Dream_httpaf.serve: no interface with address %s"
      interface
  | address::_ ->
  let listen_address = Lwt_unix.(address.ai_addr) in


  (* Bring up the Httpaf/Lwt server. Wait for the server to actually get
     started. Then, wait for the ~stop promise. If the ~stop promise ever
     resolves, stop the server. *)
  Lwt_io.establish_server_with_client_socket
    listen_address
    httpaf_connection_handler
  >>= fun server ->
  stop
  >>= fun () ->
  Lwt_io.shutdown_server server
  >>= fun () ->
  Lwt.return_unit



let run ?interface ?port ?stop ?error_handler user's_dream_handler =
  Lwt_main.run
    (serve ?interface ?port ?stop ?error_handler user's_dream_handler)
