module Dream =
struct
  include Dream_pure.Inmost
  module Log = Dream_middleware.Log
end



let address_to_string : Unix.sockaddr -> string = function
  | ADDR_UNIX path -> path
  | ADDR_INET (address, port) ->
    Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port

let to_dream_method = function
  | #Dream.method_ as method_ -> method_
  | `Other method_ -> `Method method_

let to_httpaf_status = function
  | #Httpaf.Status.t as status -> status
  | `Permanent_redirect -> `Code 308
  | `Misdirected_request -> `Code 421
  | `Too_early -> `Code 425
  | `Precondition_required -> `Code 428
  | `Too_many_requests -> `Code 429
  | `Request_header_fields_too_large -> `Code 431
  | `Unavailable_for_legal_reasons -> `Code 451

let forward_body
    (response : Dream.response)
    (body : [ `write ] Httpaf.Body.t) =

  let body_stream =
    Dream.body_stream response in

  (* TODO LATER Will also need to monitor buffer accumulation and use
           flush. *)
  let rec send_body () =
    body_stream begin function
    | None -> Httpaf.Body.close_writer body
    | Some chunk ->
      Httpaf.Body.write_bigstring body chunk;
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
let wrap_handler app (user's_dream_handler : Dream.handler) =

  let httpaf_request_handler = fun client_address (conn : Httpaf.Reqd.t) ->
    Dream.Log.set_up_exception_hook ();

    (* Covert the http/af request to a Dream request. *)
    let httpaf_request : Httpaf.Request.t =
      Httpaf.Reqd.request conn in

    let client =
      address_to_string client_address in
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
    let body k =
      Httpaf.Body.schedule_read body
        ~on_eof:(fun () -> k None)
        ~on_read:(fun buffer ~off ~len ->
          k (Some (Bigarray_compat.Array1.sub buffer off len))) in

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

        let version =
          match Dream.version_override response with
          | None -> None
          | Some (major, minor) -> Some Httpaf.Version.{major; minor}
        in
        let status =
          to_httpaf_status (Dream.status response) in
        let reason =
          Dream.reason_override response in
        let headers =
          Httpaf.Headers.of_list (Dream.all_headers response) in

        let httpaf_response =
          Httpaf.Response.create ?version ?reason ~headers status in
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



type error = [
  | `Bad_request of string
  | `Internal_server_error of string
  | `Exn of exn
]

type error_handler = Unix.sockaddr -> error -> Dream.response Lwt.t

let log =
  Dream.Log.source "dream.http"

let format_detail detail =
  if detail = "" then
    ""
  else
    ": " ^ detail

let default_error_handler client_address error =
  begin match error with
  | `Bad_request detail ->
    log.warning (fun log ->
      log "Bad request from %s%s"
        (address_to_string client_address) (format_detail detail))

  | `Internal_server_error detail ->
    log.error (fun log -> log "Bad response from app%s" (format_detail detail))

  | `Exn exn ->
    log.error (fun log -> log "App raised: %s" (Printexc.to_string exn));
    Printexc.get_backtrace ()
    |> Dream.Log.iter_backtrace (fun line ->
      log.error (fun log -> log "%s" line));
  end;

  Dream.respond ""



let wrap_error_handler (user's_error_handler : error_handler) =

  let httpaf_error_handler = fun client_address ?request error start_response ->
    ignore request;

    Lwt.async begin fun () ->
      Lwt.catch begin fun () ->
        let open Lwt.Infix in

        let error =
          match error with
          | `Exn exn -> `Exn exn
          | `Bad_request -> `Bad_request ""
          | `Bad_gateway
          | `Internal_server_error ->
            `Internal_server_error "Content-Length missing or negative"
        in

        user's_error_handler client_address error
        >>= fun response ->

        let headers =
          Httpaf.Headers.of_list (Dream.all_headers response) in
        let body =
          start_response headers in

        forward_body response body;

        Lwt.return_unit
      end
      @@ fun exn ->
        log.error (fun log ->
          log "Error handler raised: %s" (Printexc.to_string exn));

        Printexc.get_backtrace ()
        |> Dream.Log.iter_backtrace (fun line ->
          log.error (fun log -> log "%s" line));

        Lwt.return_unit
    end
  in

  httpaf_error_handler



let default_interface = "localhost"
let default_port = 8080
let never = fst (Lwt.wait ())



let serve_with_caller_name
    caller
    ?(interface = default_interface) ?(port = default_port)
    ?(stop = never)
    ?(app = Dream.app ())
    ?(error_handler = default_error_handler)
    user's_dream_handler =

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
    Printf.ksprintf failwith "Dream.%s: no interface with address %s"
      caller interface
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

let serve =
  serve_with_caller_name "serve"



(* TODO LATER Correct protocol scheme once there is HTTPS support. *)
let run
    ?(interface = default_interface) ?(port = default_port)
    ?(stop = never)
    ?app
    ?error_handler
    ?(greeting = true)
    ?(stop_on_input = true)
    ?(graceful_stop = true)
    user's_dream_handler =

  let log = Dream.Log.convenience_log in

  if greeting then begin
    let hostname =
      match interface with
      | "localhost" | "127.0.0.1" | "0.0.0.0" -> "localhost"
      | interface -> interface
    in

    log "Running on http://%s:%i" hostname port;
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

    serve_with_caller_name "run"
      ~interface ~port ~stop ?app ?error_handler user's_dream_handler
    >>= fun () ->

    if not graceful_stop then
      Lwt.return_unit
    else begin
      log "Stopping; allowing 1 second for requests to finish";
      Lwt_unix.sleep 1.
    end
  end


(* TODO LATER Project homepage to greeting message. *)
(* TODO LATER Terminal options docs, etc., log viewers, for line wrapping. *)
(* TODO DOC Gradual replacement of run by serve. *)
(* TODO LATER Don't print the port if it is the default for the scheme. *)

(* TODO LATER Router API sketch:

@@ Dream.route [
  Dream.get "/foo" handler;
  Drema.post "/bar" handler2;
  Dream.(middleware [form; csrf]) [
    Dream.post "/baz" handler3;
    Dream.post "/omg" handler4;
  ]
]

so

type route
val route : route list -> middleware
val get : string -> handler -> route
val post ...
val middleware : middleware list -> route list -> route
val routes : route list -> route   as an abbreviation for middleware?

Might be nice if middleware could just take a single middleware, but there is no
function composition operator in OCaml.

Dream.middleware [Dream.form; Dream.csrf] [
  Dream.post "/a" ...;
  Dream.post "/b" ...;
]

Dream.middleware (Dream.form @@@ Dream.csrf) [
  Dream.post "/a" ...;
  Dream.post "/b" ...;
]

The list is still better - it is easier to type, and introduces no new concepts.

Prefix middleware is a must, and it needs to interact with the router.
 *)
