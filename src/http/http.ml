open Dream_pure

let address_to_string : Unix.sockaddr -> string = function
  | ADDR_UNIX path -> path
  | ADDR_INET (address, port) ->
    Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port

let forward_body
    (response : Dream_.response)
    (body : [ `write ] Httpaf.Body.t) =

  let body_stream =
    Dream_.internal_body_stream response [@ocaml.warning "-3"] in

  (* TODO LATER Will also need to monitor buffer accumulation and use
           flush. *)
  let rec send_body () =
    body_stream begin function
    | None -> Httpaf.Body.close_writer body
    | Some chunk ->
      Httpaf.Body.write_string body chunk;
      send_body ()
    end
  in

  send_body ()



(* Wraps the user's Dream handler in the kind of handler expected by http/af.
   The scheme is simple: wait for http/af "Reqd.t"s (partially parsed
   connections), convert their fields to Dream.request, call the user's handler,
   wait for the Dream.response, and then convert it to an http/af Response and
   sned it.

   If the user's handler (wrongly) leaks any exceptions or rejections, they are
   passed to http/af to end up in the error handler. This is a low-level handler
   that ordinarily shouldn't be relied on by the user - this is just our last
   chance to tell the user that something is wrong with their app. *)
let wrap_handler app (user's_dream_handler : Dream_.handler) =

  let httpaf_request_handler = fun client_address (conn : Httpaf.Reqd.t) ->

    (* Covert the http/af request to a Dream request. *)
    let httpaf_request : Httpaf.Request.t =
      Httpaf.Reqd.request conn in

    let client =
      address_to_string client_address in
    let method_ =
      httpaf_request.meth in
    let target =
      httpaf_request.target in
    let version =
      (httpaf_request.version.major, httpaf_request.version.minor) in
    let headers =
      Httpaf.Headers.to_list httpaf_request.headers in

    let body =
      Httpaf.Reqd.request_body conn in
    let body_stream k =
      Httpaf.Body.schedule_read body
        ~on_eof:(fun () -> k None)
        ~on_read:(fun buffer ~off ~len ->
          k (Some (Bigarray_compat.Array1.sub buffer off len)))
    in

    let request : Dream_.request =
      Dream_.internal_create_request
        ~app ~client ~method_ ~target ~version ~headers ~body_stream
          [@ocaml.warning "-3"]
    in

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
        >>= fun (response : Dream_.response) ->

        let status =
          (Dream_.status response :> Httpaf.Status.t) in
        let headers =
          Httpaf.Headers.of_list (Dream_.headers response) in

        let httpaf_response =
          Httpaf.Response.create ~headers status in
        let body =
          Httpaf.Reqd.respond_with_streaming conn httpaf_response in

        forward_body response body;

        Lwt.return_unit
      end
      @@ fun exn ->
        Httpaf.Reqd.report_exn conn exn;
        Lwt.return_unit
    end
  in

  httpaf_request_handler



type error_handler =
  Unix.sockaddr ->
  [ `Bad_request | `Bad_gateway | `Internal_server_error | `Exn of exn ] ->
    Dream_.response Lwt.t

let log =
  Log.source "dream.http"

let default_error_handler client_address error =
  begin match error with
  | `Bad_request ->
    log.warning (fun m ->
      m "Bad request from %s" (address_to_string client_address))

  | `Bad_gateway | `Internal_server_error ->
    log.error (fun m -> m "Content-Length missing when required, or negative")

  | `Exn exn ->
    log.error (fun m -> m "Application leaked %s" (Printexc.to_string exn));
    Printexc.get_backtrace ()
    |> Log.iter_backtrace (fun line -> log.error (fun m -> m "%s" line));
  end;

  Lwt.return @@ Dream_.response ~headers:["Content-Length", "0"] ()



let wrap_error_handler (user's_error_handler : error_handler) =

  let httpaf_error_handler = fun client_address ?request error start_response ->
    ignore request;

    Lwt.async begin fun () ->
      Lwt.catch begin fun () ->
        let open Lwt.Infix in

        user's_error_handler client_address error
        >>= fun response ->

        let headers =
          Httpaf.Headers.of_list (Dream_.headers response) in
        let body =
          start_response headers in

        forward_body response body;

        Lwt.return_unit
      end
      @@ fun exn ->
        log.error (fun m ->
          m "Double fault: error handler raised %s" (Printexc.to_string exn));

        Printexc.get_backtrace ()
        |> Log.iter_backtrace (fun line -> log.error (fun m -> m "%s" line));

        Lwt.return_unit
    end
  in

  httpaf_error_handler



let serve =
  let never = fst (Lwt.wait ()) in

  fun
    ?(interface = "localhost") ?(port = 8080)
    ?(stop = never)
    ?(app = Dream_.app ())
    ?(error_handler = default_error_handler)
    user's_dream_handler ->

  (* Create the wrapped Httpaf handler from the user's Dream handler. *)
  let httpaf_connection_handler =
    Httpaf_lwt_unix.Server.create_connection_handler
      ~request_handler:(wrap_handler app user's_dream_handler)
      ~error_handler:(wrap_error_handler error_handler)
  in


  let open Lwt.Infix in

  (* Look up the low-level address corresponding to the interface. Hopefully,
     this is a local interface. *)
  Lwt_unix.getaddrinfo interface (string_of_int port) []
  >>= fun addresses ->
  match addresses with
  | [] ->
    (* TODO The function might be Dream.run, not Dream.serve. *)
    Printf.ksprintf failwith "Dream.serve: no interface with address %s"
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



let run ?interface ?port ?stop ?app ?error_handler user's_dream_handler =
  Lwt_main.run
    (serve ?interface ?port ?stop ?app ?error_handler user's_dream_handler)



(* TODO Consider also lazily setting async_exception_hook. *)
