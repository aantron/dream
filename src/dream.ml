(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Catch = Dream__server.Catch
module Cipher = Dream__cipher.Cipher
module Cookie = Dream__server.Cookie
module Content_length = Dream__server.Content_length
module Csrf = Dream__server.Csrf
module Dream = Dream_pure.Inmost
module Echo = Dream__server.Echo
module Error_handler = Dream__http.Error_handler
module Flash = Dream__server.Flash
module Form = Dream__server.Form
module Formats = Dream_pure.Formats
module Graphql = Dream__graphql.Graphql
module Helpers = Dream__server.Helpers
module Http = Dream__http.Http
module Lowercase_headers = Dream__server.Lowercase_headers
module Method = Dream_pure.Method
module Origin_referrer_check = Dream__server.Origin_referrer_check
module Query = Dream__server.Query
module Random = Dream__cipher.Random
module Router = Dream__server.Router
module Site_prefix = Dream__server.Site_prefix
module Sql = Dream__sql.Sql
module Sql_session = Dream__sql.Session
module Static = Dream__unix.Static
module Status = Dream_pure.Status
module Stream = Dream_pure.Stream
module Tag = Dream__server.Tag
module Upload = Dream__server.Upload



(* Initialize clock handling and random number generator. These are
   platform-specific, differing between Unix and Mirage. This is the Unix
   initialization. *)

module Log =
struct
  include Dream__server.Log
  include Dream__server.Log.Make (Ptime_clock)
end

let default_log =
  Log.sub_log (Logs.Src.name Logs.default)

let () =
  Log.initialize ~setup_outputs:Fmt_tty.setup_std_outputs

let now () =
  Ptime.to_float_s (Ptime.v (Ptime_clock.now_d_ps ()))

let () =
  Random.initialize Mirage_crypto_rng_lwt.initialize

module Session =
struct
  include Dream__server.Session
  include Dream__server.Session.Make (Ptime_clock)
end



(* Types *)

type request = Dream.request
type response = Dream.response
type handler = Dream.handler
type middleware = Dream.middleware
type route = Router.route

type 'a message = 'a Dream.message
type client = Dream.client
type server = Dream.server
type 'a promise = 'a Dream.promise



(* Methods *)

include Method



(* Status codes *)

include Status



(* Requests *)

let client = Helpers.client
let https = Helpers.https
let method_ = Dream.method_
let target = Dream.target
let prefix = Router.prefix
let path = Router.path
let version = Dream.version
let set_client = Helpers.set_client
let set_method_ = Dream.set_method_
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
let status = Dream.status



(* Headers *)

let header = Dream.header
let headers = Dream.headers
let all_headers = Dream.all_headers
let has_header = Dream.has_header
let add_header = Dream.add_header
let drop_header = Dream.drop_header
let set_header = Dream.set_header



(* Cookies *)

let set_cookie = Cookie.set_cookie
let drop_cookie = Cookie.drop_cookie
let cookie = Cookie.cookie
let all_cookies = Cookie.all_cookies



(* Bodies *)

let body = Dream.body
let set_body = Dream.set_body
let read = Dream.read
let set_stream = Dream.set_stream
let write = Dream.write
let flush = Dream.flush
let close_stream = Dream.close_stream
type buffer = Stream.buffer
type stream = Stream.stream
let client_stream = Dream.client_stream
let server_stream = Dream.server_stream
let set_client_stream = Dream.set_client_stream
let next = Dream.next
let write_buffer = Dream.write_buffer



(* JSON *)

let origin_referrer_check = Origin_referrer_check.origin_referrer_check



(* Forms *)

type 'a form_result = 'a Form.form_result
let form = Form.form ~now
type multipart_form = Upload.multipart_form
let multipart = Upload.multipart ~now
type part = Upload.part
let upload = Upload.upload
let upload_part = Upload.upload_part
type csrf_result = Csrf.csrf_result
let csrf_token = Csrf.csrf_token ~now
let verify_csrf_token = Csrf.verify_csrf_token ~now



(* Templates *)

let form_tag ?method_ ?target ?enctype ?csrf_token ~action request =
  Tag.form_tag ~now ?method_ ?target ?enctype ?csrf_token ~action request



(* Middleware *)

let no_middleware = Dream.no_middleware
let pipeline = Dream.pipeline



(* Routing *)

let router = Router.router
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



(* Static files *)

let static = Static.static
let from_filesystem = Static.from_filesystem
let mime_lookup = Static.mime_lookup



(* Sessions *)

let session = Session.session
let put_session = Session.put_session
let all_session_values = Session.all_session_values
let invalidate_session = Session.invalidate_session
let memory_sessions = Session.memory_sessions
let cookie_sessions = Session.cookie_sessions
let sql_sessions = Sql_session.sql_sessions
let session_id = Session.session_id
let session_label = Session.session_label
let session_expires_at = Session.session_expires_at



(* Flash messages *)

let flash_messages = Flash.flash_messages
let flash = Flash.flash
let put_flash = Flash.put_flash



(* WebSockets *)

type websocket = Dream.websocket
let websocket = Dream.websocket
let send = Dream.send
let receive = Dream.receive
let close_websocket = Dream.close_websocket



(* GraphQL *)

let graphql = Graphql.graphql
let graphiql = Graphql.graphiql



(* SQL *)

let sql_pool = Sql.sql_pool
let sql = Sql.sql



(* Logging *)

let logger = Log.logger
let log = Log.convenience_log
type ('a, 'b) conditional_log = ('a, 'b) Log.conditional_log
type log_level = Log.log_level
let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug
type sub_log = Log.sub_log = {
  error : 'a. ('a, unit) conditional_log;
  warning : 'a. ('a, unit) conditional_log;
  info : 'a. ('a, unit) conditional_log;
  debug : 'a. ('a, unit) conditional_log;
}
let sub_log = Log.sub_log
let initialize_log = Log.initialize_log
let set_log_level = Log.set_log_level



(* Errors *)

type error = Catch.error = {
  condition : [
    | `Response of Dream.response
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
  request : Dream.request option;
  response : Dream.response option;
  client : string option;
  severity : Log.log_level;
  will_send_response : bool;
}
type error_handler = Catch.error_handler
let error_template = Error_handler.customize
let debug_error_handler = Error_handler.debug_error_handler
let catch = Catch.catch



(* Servers *)

let run = Http.run
let serve = Http.serve
let lowercase_headers = Lowercase_headers.lowercase_headers
let content_length = Content_length.content_length
let with_site_prefix = Site_prefix.with_site_prefix



(* Web formats *)

include Formats



(* Cryptography *)

let set_secret = Cipher.set_secret
let random = Random.random
let encrypt = Cipher.encrypt
let decrypt = Cipher.decrypt



(* Custom fields *)

type 'a field = 'a Dream.field
let new_field = Dream.new_field
let field = Dream.field
let set_field = Dream.set_field



(* Testing. *)

let request = Helpers.request_with_body

(* TODO Restore the ability to test with a prefix and re-enable the
   corresponding tests. *)
let test ?(prefix = "") handler request =
  let app =
    Content_length.content_length
    @@ Site_prefix.with_site_prefix prefix
    @@ handler
  in

  Lwt_main.run (app request)

let sort_headers = Dream.sort_headers
let echo = Echo.echo



(* Deprecated helpers. *)

let with_client client message =
  Helpers.set_client message client;
  message

let with_method_ method_ message =
  Dream.set_method_ message method_;
  message

let with_version version message =
  Dream.set_version message version;
  message

let with_path path message =
  Router.set_path message path;
  message

let with_header name value message =
  Dream.set_header message name value;
  message

let with_body body message =
  Dream.set_body message body;
  message

let with_stream message =
  Dream.set_stream message;
  message

type 'a local = 'a Dream.field
let new_local = Dream.new_field
let local = Dream.field

let with_local key value message =
  Dream.set_field message key value;
  message

let first message =
  message

let last message =
  message
