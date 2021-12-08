type request = Dream.request
type response = Dream.response
type 'a promise = 'a Lwt.t

type method_ = Dream.method_

(* TODO Is this the right representation? *)
type connection =
  | Cleartext of Httpaf_lwt_unix.Client.t
  | SSL of Httpaf_lwt_unix.Client.SSL.t
  | H2 of H2_lwt_unix.Client.SSL.t (* TODO No h2c support. *)

type host = string * string * int
(* TODO But what should a host be? An unresolved hostname:port, or a resolved
   hostname:port? Hosts probably also need a comparison function or
   something. And probably a pretty-printing function. These things are entirely
   abstract. But, because they are abstract, it's possible to change the
   implementation, in particular to switch from unresolved to resolved hosts.
   Using unresolved hosts implies doing DNS before deciding whether each request
   can reuse a connection from the pool. Though that can be avoided by using a
   DNS cache, it seems like the pool should short-circuit that entire process.
   So, this becomes some kind of scheme-host-port triplet. *)
(* TODO Also, how should this work with HTTP/2 and multiplexing? Need to address
   that next. *)
(* TODO The scheme is probably not sufficient. Will also need the negotiated
   protocol, as an https connection might have been upgraded to HTTP/2 or not at
   the server's discretion during ALPN. *)

type connection_pool = {
  obtain : host -> request -> connection option promise;
  return :
    host -> request -> response -> connection -> (connection -> unit promise) ->
      unit promise;
}
(* TODO Return needs to provide a function for destroying a connection. *)

let connection_pool ~obtain ~return =
  {obtain; return}

let _no_pooling =
  connection_pool
    ~obtain:(fun _host _request ->
      Lwt.return_none)
    ~return:(fun _host _request _response connection destroy ->
      destroy connection)

(* TODO Non-trivial pools should always be generated, i.e. this should be a
   function of at least (). However, we are just doing proof-of-concept code
   here, to work out the protocol details, rather than a great connection
   pool. Most connection pool should also examine the Connection: header, and
   perhaps other headers. *)
let indefinite_keepalive =
  let pool = Hashtbl.create 32 in
  connection_pool
    ~obtain:(fun host _request ->
      match Hashtbl.find_opt pool host with
      | Some connection ->
        Hashtbl.remove pool host;
        Lwt.return (Some connection)
      | None ->
        Lwt.return_none)
    ~return:(fun host _request _response connection _destroy ->
      Hashtbl.add pool host connection;
      Lwt.return_unit)

(* TODO How should the host and port be represented? *)
(* TODO Good error handling. *)
(* TODO Probably change the default to one per-process pool with some
   configuration. *)
let send ?(connection_pool = indefinite_keepalive) hyper_request =
  let uri = Uri.of_string (Dream.target hyper_request) in
  let scheme = Uri.scheme uri |> Option.get
  and host = Uri.host uri |> Option.get
  and port = Uri.port uri |> Option.value ~default:80
  and method_ = Dream.method_ hyper_request
  and path_and_query = Uri.path_and_query uri
  in
  (* TODO Usage of Option.get above is temporary, though failure to provide a
     host should probably be a logic error, and doesn't have to be reported in a
     "neat" way - just a debuggable way. The port can be inferred from the
     scheme if it is missing. We are assuming http:// for now. *)

  let host_key = (scheme, host, port) in

  let%lwt connection =
    match%lwt connection_pool.obtain host_key hyper_request with
    | Some connection ->
      Lwt.return connection
    | None ->
      let%lwt addresses =
        Lwt_unix.getaddrinfo
          host (string_of_int port) [Unix.(AI_FAMILY PF_INET)] in
      let address = (List.hd addresses).Unix.ai_addr in
      (* TODO Note: this can raise. *)

      let socket = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
      let%lwt () = Lwt_unix.connect socket address in

      match scheme with
      | "https" ->
        (* TODO The context needs to be created once per process, or a cache
           should be used. *)
        let context = Ssl.(create_context TLSv1_2 Client_context) in
        (* TODO For WebSockets (wss://), the client should probably do SSL
           without offering h2 by ALPN. Do any servers implement WebSockets over
           HTTP/2? *)
        Ssl.set_context_alpn_protos context ["h2"; "http/1.1"];
        let%lwt ssl_socket = Lwt_ssl.ssl_connect socket context in
        (* TODO Next line is pretty suspicious. *)
        let underlying = Lwt_ssl.ssl_socket ssl_socket |> Option.get in
        begin match Ssl.get_negotiated_alpn_protocol underlying with
        | Some "h2" ->
          (* TODO What about the error handler? *)
          let%lwt connection =
            H2_lwt_unix.Client.SSL.create_connection
              ~error_handler:ignore
              ssl_socket
          in
          Lwt.return (H2 connection)
        | _ ->
          let%lwt connection =
            Httpaf_lwt_unix.Client.SSL.create_connection ssl_socket in
          Lwt.return (SSL connection)
        end
        (* TODO Need to do server certificate validation here, etc. *)
      | _ -> (* TODO Should be a check for http specifically. *)
        let%lwt connection = Httpaf_lwt_unix.Client.create_connection socket in
        Lwt.return (Cleartext connection)
  in

  (* TODO These sorts of things can probably be done by passing the client
     modules in as first-class modules. The code might be not so clear to read,
     though. *)
  let destroy connection =
    match connection with
    | Cleartext connection -> Httpaf_lwt_unix.Client.shutdown connection
    | SSL connection -> Httpaf_lwt_unix.Client.SSL.shutdown connection
    | H2 connection -> H2_lwt_unix.Client.SSL.shutdown connection
  in

  let request connection =
    match connection with
    | Cleartext connection -> Httpaf_lwt_unix.Client.request connection
    | SSL connection -> Httpaf_lwt_unix.Client.SSL.request connection
    | H2 _connection -> assert false
      (* TODO H2 is just a separate CF branch for now. *)
  in

  let response_promise, received_response = Lwt.wait () in

  begin match connection with
  | Cleartext _ | SSL _ ->
  (* TODO Did not indent the case body; quick and dirty "get it working"
     version. *)

  (* TODO Do we now want to store the verson? *)
  let response_handler
      (httpaf_response : Httpaf.Response.t)
      httpaf_response_body =

    (* TODO Using Dream.stream is awkward here, but it allows getting a response
       with a stream inside it without immeidately having to modify Dream. Once
       that is fixed, the Lwt.async can be removed, most likely. Dream.stream's
       signature will change in Dream either way, so it's best to just hold off
       tweaking it now. *)
    Lwt.async begin fun () ->
      let%lwt hyper_response =
        Dream.stream
          ~code:(Httpaf.Status.to_code httpaf_response.status)
          ~headers:(Httpaf.Headers.to_list httpaf_response.headers)
          (fun _response -> Lwt.return ())
      in
      Lwt.wakeup_later received_response hyper_response;

      (* TODO A janky reader. Once Dream.stream is fixed and streams are fully
         exposed, this can become a good pull-reader. *)
      let rec receive () =
        Httpaf.Body.Reader.schedule_read
          httpaf_response_body
          ~on_eof:(fun () ->
            Lwt.async (fun () ->
              let%lwt () = Dream.close_stream hyper_response in
              connection_pool.return
                host_key hyper_request hyper_response connection
                destroy))
              (* TODO Make sure there is a way for the reader to abort reading
                 the stream and yet still get the socket closed. *)
          ~on_read:(fun buffer ~off ~len ->
            Lwt.async (fun () ->
              let%lwt () =
                Dream.write_buffer
                  ~offset:off ~length:len hyper_response buffer in
              Lwt.return (receive ())))
      in
      receive ();

      Lwt.return ()
    end
  in

  let httpaf_request =
    Httpaf.Request.create
      ~headers:(Httpaf.Headers.of_list (Dream.all_headers hyper_request))
      (Httpaf.Method.of_string (Dream.method_to_string method_))
      path_and_query in
  let httpaf_request_body =
    request
      connection
      ~error_handler:(fun _ -> failwith "Protocol error") (* TODO *)
      ~response_handler
      httpaf_request in

  let rec send () =
    Dream.body_stream hyper_request
    |> fun stream ->
      Dream.next stream ~data ~close ~flush ~ping ~pong

  (* TODO Implement flow control like on the server side, using flush. *)
  and data buffer offset length _binary _fin =
    Httpaf.Body.Writer.write_bigstring
      httpaf_request_body
      ~off:offset
      ~len:length
      buffer;
    send ()

  and close _code = Httpaf.Body.Writer.close httpaf_request_body
  and flush () = send ()
  and ping _buffer _offset _length = send ()
  and pong _buffer _offset _length = send ()

  in

  send ()

  | H2 connection' ->
    (* TODO This is a nasty duplicate of the above case, specialized for H2. See
       comments above. *)
    let response_handler (h2_response : H2.Response.t) h2_response_body =

      Lwt.async begin fun () ->
        let%lwt hyper_response =
          Dream.stream
            ~code:(H2.Status.to_code h2_response.status)
            ~headers:(H2.Headers.to_list h2_response.headers)
            (fun _response -> Lwt.return ())
        in
        Lwt.wakeup_later received_response hyper_response;

        let rec receive () =
          H2.Body.schedule_read
            h2_response_body
            ~on_eof:(fun () ->
              Lwt.async (fun () ->
                let%lwt () = Dream.close_stream hyper_response in
                connection_pool.return
                  host_key hyper_request hyper_response connection
                  destroy))
            ~on_read:(fun buffer ~off ~len ->
              Lwt.async (fun () ->
                let%lwt () =
                  Dream.write_buffer
                    ~offset:off ~length:len hyper_response buffer in
                Lwt.return (receive ())))
        in
        receive ();

        Lwt.return ()
      end
    in

    let h2_request =
      H2.Request.create
        ~headers:(H2.Headers.of_list (Dream.all_headers hyper_request))
        ~scheme
        (H2.Method.of_string (Dream.method_to_string method_))
        path_and_query in
    let h2_request_body =
      H2_lwt_unix.Client.SSL.request
        connection'
        h2_request
        ~error_handler:(fun _ -> failwith "Protocol error")
        ~response_handler in

    let rec send () =
      Dream.body_stream hyper_request
      |> fun stream ->
        Dream.next stream ~data ~close ~flush ~ping ~pong

    and data buffer offset length _binary _fin =
      H2.Body.write_bigstring
        h2_request_body
        ~off:offset
        ~len:length
        buffer;
      send ()

    and close _code = H2.Body.close_writer h2_request_body
    and flush () = send ()
    and ping _buffer _offset _length = send ()
    and pong _buffer _offset _length = send ()

    in

    send ()
  end;

  response_promise



(* TODO Which function should be the most fundamental function? Probably the
   request -> response runner. But it's probably not the most convenient for
   general usage.

   How should the host and port be represented? Can probably just allow them in
   [target], but also allow overriding them so that only the path and query are
   used. This could get confusing, though.

   To start with, implement a good request -> response runner that does the
   basics: create a request, allow streaming out its body, receive a response,
   allow streaming in its body. After that, elaborate. Probably should start
   with HTTP/2 and SSL.

   How are non-response errors reported? *)
