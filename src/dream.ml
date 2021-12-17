(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Dream_pure.Status
include Dream_pure.Stream
include Dream_pure.Method
include Dream_pure.Inmost
include Dream_pure.Formats

include Dream__server.Log
include Dream__server.Log.Make (Ptime_clock)
(* Initalize logs with the default reporter which uses [Ptime_clock], this
   function is a part of [Dream__server.Log.Make], it's why it is not prepended
   by a module name. *)
let () =
  initialize ~setup_outputs:Fmt_tty.setup_std_outputs
include Dream__server.Echo

let default_log =
  Dream__server.Log.sub_log (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

include Dream__server.Router
include Dream__unix.Static

include Dream__cipher.Cipher
include Dream__server.Cookie

include Dream__server.Session
include Dream__server.Session.Make (Ptime_clock)
let sql_sessions = Dream__sql.Session.middleware

include Dream__server.Flash

include Dream__server.Origin_referrer_check
include Dream__server.Form
include Dream__server.Upload
include Dream__server.Csrf

let content_length =
  Dream__server.Content_length.content_length

include Dream__graphql.Graphql
include Dream__sql.Sql

include Dream__http.Http

include Dream__server.Lowercase_headers
include Dream__server.Catch
include Dream__server.Site_prefix

let debug_error_handler =
  Dream__http.Error_handler.debug_error_handler
let error_template =
  Dream__http.Error_handler.customize

let () = Dream__cipher.Random.initialize Mirage_crypto_rng_lwt.initialize

let random =
  Dream__cipher.Random.random

(* TODO Restore the ability to test with a prefix and re-enable the
   corresponding tests. *)
let test ?(prefix = "") handler request =
  let app =
    content_length
    @@ with_site_prefix prefix
    @@ handler
  in

  Lwt_main.run (app request)

let log =
  Dream__server.Log.convenience_log

include Dream__server.Tag

let respond =
  Dream__server.Helpers.respond

let redirect =
  Dream__server.Helpers.redirect

let stream =
  Dream__server.Helpers.stream

let empty =
  Dream__server.Helpers.empty

let not_found =
  Dream__server.Helpers.not_found

let now () = Ptime.to_float_s (Ptime.v (Ptime_clock.now_d_ps ()))

let form = form ~now
let multipart = multipart ~now
let csrf_token = csrf_token ~now
let verify_csrf_token = verify_csrf_token ~now
let form_tag ?method_ ?target ?enctype ?csrf_token ~action request =
  form_tag ~now ?method_ ?target ?enctype ?csrf_token ~action request

let client =
  Dream__server.Helpers.client
let set_client =
  Dream__server.Helpers.set_client
let https =
  Dream__server.Helpers.https
let html =
  Dream__server.Helpers.html
let json =
  Dream__server.Helpers.json

include Dream__server.Query

let request =
  Dream__server.Helpers.request_with_body

let response =
  Dream__server.Helpers.response_with_body

let with_client client message =
  set_client message client;
  message

let with_method_ method_ message =
  set_method_ message method_;
  message

let with_version version message =
  set_version message version;
  message

let with_path path message =
  set_path message path;
  message

let with_header name value message =
  set_header message name value;
  message

let with_body body message =
  set_body message body;
  message

let with_stream message =
  set_stream message;
  message

type 'a local = 'a field
let new_local = new_field
let local = field

let with_local key value message =
  set_field message key value;
  message

let first message =
  message

let last message =
  message
