module Catch = Dream__server.Catch
module Error_template = Dream__server.Error_template
module Method = Dream_pure.Method
module Helpers = Dream__server.Helpers
module Log = Dream__server.Log
module Message = Dream_pure.Message
module Status = Dream_pure.Status
module Stream = Dream_pure.Stream
module Random = Dream__cipher.Random
module Router = Dream__server.Router
module Query = Dream__server.Query
module Cookie = Dream__server.Cookie
module Tag = Dream__server.Tag


open Rresult
open Lwt.Infix

let to_dream_method meth = H1.Method.to_string meth |> Method.string_to_method
let to_httpaf_status status = Status.status_to_int status |> H1.Status.of_code
let ( >>? ) = Lwt_result.bind

let wrap_handler_httpaf _user's_error_handler user's_dream_handler =
  let httpaf_request_handler = fun _ reqd ->
    let httpaf_request = H1.Reqd.request reqd in
    let method_ = to_dream_method httpaf_request.meth in
    let target  = httpaf_request.target in
    let _version = (httpaf_request.version.major, httpaf_request.version.minor) in
    let headers = H1.Headers.to_list httpaf_request.headers in
    let body    = H1.Reqd.request_body reqd in

    let read ~data ~flush:_ ~ping:_ ~pong:_ ~close ~exn:_ =
      H1.Body.Reader.schedule_read
        body
        ~on_eof:(fun () -> close 1000)
        ~on_read:(fun buffer ~off ~len -> data buffer off len true false)
    in
    let close _close =
      H1.Body.Reader.close body in
    let abort _close =
      H1.Body.Reader.close body in
    let body =
      Stream.reader ~read ~close ~abort in

    let client_stream = Stream.(stream no_reader no_writer) in
    let server_stream = Stream.(stream body no_writer) in

    let request = Message.request ~method_ ~target ~headers client_stream server_stream in

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
        (* Do the big call. *)
        let%lwt response = user's_dream_handler request in

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
            H1.Headers.of_list (Message.all_headers response) in

          (* let version =
            match Dream.version_override response with
            | None -> None
            | Some (major, minor) -> Some Httpaf.Version.{major; minor}
          in *)
          let status =
            to_httpaf_status (Message.status response) in
          (* let reason =
            Dream.reason_override response in *)

          let httpaf_response =
            H1.Response.create ~headers status in
          let body =
            H1.Reqd.respond_with_streaming reqd httpaf_response in

          Adapt.forward_body response body;

          Lwt.return_unit
        in

        forward_response response
      end
      @@ fun exn ->
        (* TODO LATER There was something in the fork changelogs about not
           requiring report_exn. Is it relevant to this? *)
        H1.Reqd.report_exn reqd exn;
        Lwt.return_unit
    end
  in

  httpaf_request_handler

let request_handler
  : type reqd headers request response ro wo.
    Catch.error_handler -> Message.handler ->
      _ -> _ -> reqd ->
      (reqd, headers, request, response, ro, wo) Alpn.protocol -> unit
  = fun (user's_error_handler : Catch.error_handler)
      (user's_dream_handler : Message.handler) -> ();
    fun _ _ reqd -> function
    | Alpn.HTTP_1_1 _ ->
      wrap_handler_httpaf user's_error_handler user's_dream_handler () reqd
    | _ -> assert false

let error_handler
  : type reqd headers request response ro wo.
    Catch.error_handler ->
    _ -> (reqd, headers, request, response, ro, wo) Alpn.protocol ->
      ?request:request -> _ -> (headers -> wo) -> unit
  = fun
      (user's_error_handler : Catch.error_handler) -> ();
    fun client protocol ?request error respond ->
    match protocol with
    | Alpn.HTTP_1_1 _ ->
      let start_response hdrs : H1.Body.Writer.t =
        respond hdrs
      in
      Error_handler.httpaf user's_error_handler client ?request:(Some request) error start_response
    | _ -> assert false (* TODO *)

let handler user_err user_resp =
  {
    Alpn.error=(fun edn protocol ?request error respond ->
      error_handler user_err edn protocol ?request error respond);
    request=(fun flow edn reqd protocol ->
      request_handler user_err user_resp flow edn reqd protocol)
  }


module Make (Pclock : Mirage_clock.PCLOCK) (Time : Mirage_time.S) (Stack : Tcpip.Stack.V4V6) = struct
  include Dream_pure
  include Method
  include Status

  include Log
  include Log.Make (Pclock)
  include Dream__server.Echo

  let default_log =
    Log.sub_log (Logs.Src.name Logs.default)

  let error = default_log.error
  let warning = default_log.warning
  let info = default_log.info
  let debug = default_log.debug

  module Session = struct
    include Dream__server.Session
    include Dream__server.Session.Make (Pclock)
  end
  module Flash = Dream__server.Flash


  include Dream__server.Origin_referrer_check
  include Dream__server.Form
  include Dream__server.Upload
  include Dream__server.Csrf


  include Dream__server.Catch
  include Dream__server.Site_prefix

  let error_template =
    Error_handler.customize
(*
  let random =
    Dream__cipher.Random.random
 *)
  include Formats

  (* Types *)

  type request = Message.request
  type response = Message.response
  type handler = Message.handler
  type middleware = Message.middleware
  type route = Router.route

  type 'a message = 'a Message.message
  type client = Message.client
  type server = Message.server
  type 'a promise = 'a Message.promise


  (* Requests *)


  let body_stream = Message.server_stream
  let client = Helpers.client
  let method_ = Message.method_
  let target = Message.target
  let prefix = Router.prefix
  let path = Router.path
  let set_client = Helpers.set_client
  let set_method_ = Message.set_method_
  let query = Query.query
  let queries = Query.queries
  let all_queries = Query.all_queries

  (* Responses *)

  let response = Helpers.response_with_body
  let respond = Helpers.respond
  let html = Helpers.html
  let json = Helpers.json
  let redirect = Helpers.redirect
  let empty = Helpers.empty
  let stream = Helpers.stream
  let status = Message.status
  let read = Message.read
  let write = Message.write
  let flush = Message.flush


  (* Headers *)

  let header = Message.header
  let headers = Message.headers
  let all_headers = Message.all_headers
  let has_header = Message.has_header
  let add_header = Message.add_header
  let drop_header = Message.drop_header
  let set_header = Message.set_header

  (* Cookies *)

  let set_cookie = Cookie.set_cookie
  let drop_cookie = Cookie.drop_cookie
  let cookie = Cookie.cookie
  let all_cookies = Cookie.all_cookies


  (* Bodies *)

  let body = Message.body
  let set_body = Message.set_body
  let close = Message.close
  type buffer = Stream.buffer
  type stream = Stream.stream
  let client_stream = Message.client_stream
  let server_stream = Message.server_stream
  let set_client_stream = Message.set_client_stream
  let set_server_stream = Message.set_server_stream
  let read_stream = Stream.read
  let write_stream = Stream.write
  let flush_stream = Stream.flush
  let ping_stream = Stream.ping
  let pong_stream = Stream.pong
  let close_stream = Stream.close
  let abort_stream = Stream.abort


  (* websockets *)

  type websocket = stream * stream
  let websocket = Helpers.websocket
  type text_or_binary = [ `Text | `Binary ]
  type end_of_message = [ `End_of_message | `Continues ]
  let send = Helpers.send
  let receive = Helpers.receive
  let receive_fragment = Helpers.receive_fragment
  let close_websocket = Message.close_websocket


  (* Middleware *)

  let no_middleware = Message.no_middleware
  let pipeline = Message.pipeline


  (* Routing *)

  let router (r: route list): handler = Router.router r
  let get = Router.get
  let post = Router.post
  let put = Router.put
  let delete = Router.delete
  let head = Router.head
  let connect = Router.connect
  let options = Router.options
  let trace = Router.trace
  let patch = Router.patch
  let any = Router.any
  let not_found = Helpers.not_found
  let param = Router.param
  let scope = Router.scope
  let no_route = Router.no_route

  (* Sessions *)

  let session = Session.session
  let put_session = Session.put_session
  let all_session_values = Session.all_session_values
  let invalidate_session = Session.invalidate_session
  let memory_sessions = Session.memory_sessions
  let cookie_sessions = Session.cookie_sessions
  let session_id = Session.session_id
  let session_label = Session.session_label
  let session_expires_at = Session.session_expires_at



  (* Flash messages *)

  let flash_messages = Flash.flash_messages
  let flash = Flash.flash
  let put_flash = Flash.put_flash



  let log =
    Log.convenience_log


  let now () = Ptime.to_float_s (Ptime.v (Pclock.now_d_ps ()))

  let form = form ~now
  let multipart = multipart ~now
  let csrf_token = csrf_token ~now
  let verify_csrf_token = verify_csrf_token ~now
  let csrf_tag = Tag.csrf_tag ~now

  (* Errors *)

  type error = Catch.error = {
    condition : [
      | `Response of Message.response
      | `String of string
      | `Exn of exn
    ];
    layer : [
      | `App
      | `HTTP
      | `HTTP2
      | `TLS
      | `WebSocket
    ];
    caused_by : [
      | `Server
      | `Client
    ];
    request : Message.request option;
    response : Message.response option;
    client : string option;
    severity : Log.log_level;
    will_send_response : bool;
  }
  type error_handler = Catch.error_handler
(*   let error_template = Error_handler.customize *)
  let catch = Catch.catch

  (* Cryptography *)

  let set_secret = Cipher.set_secret
  let random = Random.random
  let encrypt = Cipher.encrypt
  let decrypt = Cipher.decrypt

  (* Custom fields *)

  type 'a field = 'a Message.field
  let new_field = Message.new_field
  let field = Message.field
  let set_field = Message.set_field

  open Paf_mirage.Make (Stack.TCP)

  let alpn =
    let module R = (val Mimic.repr tls_protocol) in
    let alpn (_, flow) = match TLS.epoch flow with
      | Ok { Tls.Core.alpn_protocol; _ } -> alpn_protocol
      | Error _ -> None in
    let peer ((ipaddr, port), _) = Fmt.str "%a:%d" Ipaddr.pp ipaddr port in
    let injection (_, flow) = R.T flow in
    { Alpn.alpn; peer; injection; }

  let built_in_middleware prefix error_handler=
    Message.pipeline [
      Dream__server.Catch.catch (Error_handler.app error_handler);
      Dream__server.Site_prefix.with_site_prefix prefix;
    ]

  let localhost_certificate =
    let crts = Rresult.R.failwith_error_msg
      (X509.Certificate.decode_pem_multiple (Cstruct.of_string Dream__certificate.localhost_certificate)) in
    let key = Rresult.R.failwith_error_msg
      (X509.Private_key.decode_pem (Cstruct.of_string Dream__certificate.localhost_certificate_key)) in
    `Single (crts, key)

  let https ?stop ~port ?(prefix= "") stack
    ?(cfg= Tls.Config.server ~certificates:localhost_certificate ())
    ?error_handler:(user's_error_handler : error_handler = Error_handler.default) (user's_dream_handler : Message.handler) =
    initialize ~setup_outputs:ignore ;
    let connect flow =
      let edn = TCP.dst flow in
      TLS.server_of_flow cfg flow
      >>= function
      | Ok flow -> Lwt.return_ok (edn, flow)
      | Error err ->
        TCP.close flow >>= fun () ->
        Lwt.return (R.error_msgf "%a" TLS.pp_write_error err)
    in
    let user's_dream_handler =
      built_in_middleware prefix user's_error_handler user's_dream_handler in
    let handler = handler user's_error_handler user's_dream_handler in
    let service = Alpn.service alpn handler connect accept close in
    init ~port stack >>= fun t ->
    let `Initialized th = serve ?stop service t in th

  let alpn protocol =
    let protocol = match protocol with
      | `H2 -> "h2"
      | `HTTP_1_1 -> "http/1.1" in
    let module R = (val Mimic.repr tcp_protocol) in
    let alpn _ = Some protocol in
    let peer ((ipaddr, port), _) = Fmt.str "%a:%d" Ipaddr.pp ipaddr port in
    let injection (_, flow) = R.T flow in
    { Alpn.alpn; peer; injection; }

  let http ?stop ~port ?(prefix= "") ?(protocol= `HTTP_1_1) stack
    ?error_handler:(user's_error_handler= Error_handler.default)
    user's_dream_handler =
    initialize ~setup_outputs:ignore ;
    let accept t = accept t >>? fun flow ->
      let edn = TCP.dst flow in
      Lwt.return_ok (edn, flow) in
    let user's_dream_handler =
      built_in_middleware prefix user's_error_handler user's_dream_handler in
    let handler = handler user's_error_handler user's_dream_handler in
    let service = Alpn.service (alpn protocol) handler Lwt.return_ok accept close in
    init ~port stack >>= fun t ->
    let `Initialized th = serve ?stop service t in th


  let validate_path request =
    let path = Dream__server.Router.path request in

    let has_slash component = String.contains component '/' in
    let has_backslash component = String.contains component '\\' in
    let has_slash = List.exists has_slash path in
    let has_backslash = List.exists has_backslash path in
    let has_dot = List.exists ((=) Filename.current_dir_name) path in
    let has_dotdot = List.exists ((=) Filename.parent_dir_name) path in
    let has_empty = List.exists ((=) "") path in
    let is_empty = path = [] in

    if has_slash ||
      has_backslash ||
      has_dot ||
      has_dotdot ||
      has_empty ||
      is_empty then
      None

    else
      let path = String.concat Filename.dir_sep path in
      if Filename.is_relative path then
        Some path
      else
        None

  (* Static files *)

  let mime_lookup filename =
    let content_type =
      match Magic_mime.lookup filename with
      | "text/html" -> Formats.text_html
      | content_type -> content_type
    in
    ["Content-Type", content_type]

  let static ~loader local_root = fun request ->

    if not @@ Method.methods_equal (Message.method_ request) `GET then
      Message.response ~status:`Not_Found Stream.empty Stream.null
      |> Lwt.return

    else
      match validate_path request with
      | None ->
        Message.response ~status:`Not_Found Stream.empty Stream.null
        |> Lwt.return

      | Some path ->
        let%lwt response = loader local_root path request in
        if not (Message.has_header response "Content-Type") then begin
          match Message.status response with
          | `OK
          | `Non_Authoritative_Information
          | `No_Content
          | `Reset_Content
          | `Partial_Content ->
            Message.add_header response "Content-Type" (Magic_mime.lookup path)
          | _ ->
            ()
        end;
        Lwt.return response

end

include Message
