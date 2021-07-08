module Dream = Dream__pure.Inmost
module Error = Dream__middleware.Error

open Rresult
open Lwt.Infix

let to_dream_method meth = Httpaf.Method.to_string meth |> Dream.string_to_method
let to_httpaf_status status = Dream.status_to_int status |> Httpaf.Status.of_code
let to_h2_status status = Dream.status_to_int status |> H2.Status.of_code
let sha1 str = Digestif.SHA1.(to_raw_string (digest_string str))
let const x = fun _ -> x
let ( >>? ) = Lwt_result.bind

let rec transmit_body request stream () =
  Lwt_stream.get stream >>= function
  | Some (buffer, off, len) ->
    Dream__pure.Body.write_bigstring buffer off len request.Dream.body >>=
    transmit_body request stream
  | None -> Dream.close_stream request

let wrap_handler_httpaf app (_user's_error_handler : Error.error_handler) (user's_dream_handler : Dream.handler) =
  let httpaf_request_handler = fun client reqd ->
    let httpaf_request = Httpaf.Reqd.request reqd in
    let method_ = to_dream_method httpaf_request.meth in
    let target  = httpaf_request.target in
    let version = (httpaf_request.version.major, httpaf_request.version.minor) in
    let headers = Httpaf.Headers.to_list httpaf_request.headers in
    let body    = Httpaf.Reqd.request_body reqd in
    let request = Dream.request_from_http ~app ~client ~method_ ~target ~version ~headers in

    Lwt.async begin fun () ->
      let%lwt () = Dream.flush request in
      let on_eof () = Dream.close_stream request |> ignore in

      let rec loop () =
        Httpaf.Body.schedule_read
          body
          ~on_eof
          ~on_read:(fun buffer ~off ~len ->
            Lwt.on_success
              (Dream__pure.Body.write_bigstring buffer off len request.body)
              loop)
      in
      loop ();
      Lwt.return_unit
    end;

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
            Httpaf.Reqd.respond_with_streaming reqd httpaf_response in

          Adapt.forward_body response body;

          Lwt.return_unit
        in

        forward_response response
      end
      @@ fun exn ->
        (* TODO LATER There was something in the fork changelogs about not
           requiring report_exn. Is it relevant to this? *)
        Httpaf.Reqd.report_exn reqd exn;
        Lwt.return_unit
    end
  in

  httpaf_request_handler

let request_handler
  : Dream.app -> Error.error_handler -> Dream.handler -> string -> [ `write ] Alpn.reqd_handler -> unit
  = fun app
      (user's_error_handler : Error.error_handler)
      (user's_dream_handler : Dream.handler) -> ();
    fun client_address -> function
    | Alpn.Reqd_handler (Alpn.HTTP_1_1, reqd) -> wrap_handler_httpaf app user's_error_handler user's_dream_handler client_address reqd
    | _ -> assert false

let error_handler
  : Dream.app -> Error.error_handler -> string -> ?request:Alpn.request -> Alpn.server_error ->
    (Alpn.headers -> [ `write ] Alpn.body) -> unit
  = fun app
      (user's_error_handler : Error.error_handler) -> ();
    fun client ?request error start_response ->
  match request with
  | Some (Alpn.Request (Alpn.HTTP_1_1, request)) ->
    let start_response hdrs : [ `write ] Httpaf.Body.t = match start_response Alpn.(Headers (HTTP_1_1, hdrs)) with
      | Alpn.(Body (HTTP_1_1, body)) -> body
      | Alpn.(Body (HTTP_2_0, _)) -> Fmt.failwith "Impossible to respond with an h2 respond to an HTTP/1.1 client" in
    Error_handler.httpaf app user's_error_handler (Some client) ?request:(Some request) error start_response
  | _ -> assert false (* TODO *)

module Make (Pclock : Mirage_clock.PCLOCK) (Time : Mirage_time.S) (Stack : Mirage_stack.V4V6) = struct
  module Method_and_status =
  struct
    include Dream__pure.Method
    include Dream__pure.Status
  end

  include Dream__pure.Inmost

  (* Eliminate optional arguments from the public interface for now. *)
  let next ~buffer ~close ~exn request =
    next ~buffer ~close ~exn request
  
  include Dream__middleware.Log
  include Dream__middleware.Log.Make (Pclock)
  include Dream__middleware.Echo
  
  let default_log =
    Dream__middleware.Log.sub_log (Logs.Src.name Logs.default)
  
  let error = default_log.error
  let warning = default_log.warning
  let info = default_log.info
  let debug = default_log.debug
  
  include Dream__middleware.Router
  
  include Dream__middleware.Session
  include Dream__middleware.Session.Make (Pclock)

  include Dream__middleware.Flash_message

  include Dream__middleware.Origin_referrer_check
  include Dream__middleware.Form
  include Dream__middleware.Upload
  include Dream__middleware.Csrf
  
  let content_length =
    Dream__middleware.Content_length.content_length
  
  include Dream__middleware.Error
  
  include Dream__middleware.Lowercase_headers
  include Dream__middleware.Catch
  include Dream__middleware.Request_id
  include Dream__middleware.Site_prefix

  let error_template =
    Error_handler.customize

  let random =
    Dream__cipher.Random.random
  (* XXX(dinosaure): [Mirage_crypto_rng_mirage] should already be initialized by
   * the [main.ml] generated by [mirage]. *)

  include Dream__pure.Formats

  let log =
    Dream__middleware.Log.convenience_log

  include Dream__middleware.Tag

  let now () = Ptime.to_float_s (Ptime.v (Pclock.now_d_ps ()))

  let form = form ~now
  let multipart = multipart ~now
  let csrf_token = csrf_token ~now
  let verify_csrf_token = verify_csrf_token ~now
  let form_tag = form_tag ~now
  
  include Dream__pure.Formats

  include Paf_mirage.Make (Time) (Stack)

  let alpn =
    let module R = (val Mimic.repr tls_protocol) in
    let alpn (_, flow) = match TLS.epoch flow with
      | Ok { Tls.Core.alpn_protocol; _ } -> alpn_protocol
      | Error _ -> None in
    let peer ((ipaddr, port), _) = Fmt.strf "%a:%d" Ipaddr.pp ipaddr port in
    let injection (_, flow) = R.T flow in
    { Alpn.alpn; peer; injection; }

  let built_in_middleware error_handler prefix =
    Dream__pure.Inmost.pipeline [
      Dream__middleware.Lowercase_headers.lowercase_headers;
      Dream__middleware.Content_length.content_length;
      Dream__middleware.Catch.catch (Error_handler.app error_handler);
      Dream__middleware.Request_id.assign_request_id;
      Dream__middleware.Site_prefix.chop_site_prefix prefix;
    ]

  let run ?stop ~port ?(prefix= "") stack cfg ?error_handler:(user's_error_handler= Error_handler.default) user's_dream_handler =
    initialize ~setup_outputs:ignore ;    
    let app = Dream__pure.Inmost.new_app () in
    let accept t = accept t >>? fun flow ->
      let edn = Stack.TCP.dst flow in
      TLS.server_of_flow cfg flow >>= function
      | Ok flow -> Lwt.return_ok (edn, flow)
      | Error err -> Lwt.return (R.error_msgf "%a" TLS.pp_write_error err) in
    let user's_dream_handler =
      built_in_middleware user's_error_handler prefix user's_dream_handler in
    let error_handler = error_handler app user's_error_handler in
    let request_handler = request_handler app user's_error_handler user's_dream_handler in
    let service = Alpn.service alpn ~error_handler ~request_handler accept close in
    init ~port stack >>= fun t ->
    let `Initialized th = serve ?stop service t in th
end

include Dream
