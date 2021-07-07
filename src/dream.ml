(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



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
include Dream__middleware.Log.Make (Ptime_clock)
(* Initalize logs with the default reporter which uses [Ptime_clock], this
   function is a part of [Dream__middleware.Log.Make], it's why it is not
   prepended by a module name. *)
let () = initialize ()
include Dream__middleware.Echo

let default_log =
  Dream__middleware.Log.sub_log (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

include Dream__middleware.Router
include Dream__middleware.Static

include Dream__middleware.Session
include Dream__middleware.Session.Make (Ptime_clock)
let sql_sessions = Dream__sql.Session.middleware

include Dream__middleware.Flash_message

include Dream__middleware.Origin_referrer_check
include Dream__middleware.Form
include Dream__middleware.Upload
include Dream__middleware.Csrf

let content_length =
  Dream__middleware.Content_length.content_length

include Dream__graphql.Graphql
include Dream__sql.Sql

include Dream__middleware.Error
include Dream__http.Http

include Dream__middleware.Lowercase_headers
include Dream__middleware.Catch
include Dream__middleware.Request_id
include Dream__middleware.Site_prefix

let error_template =
  Dream__http.Error_handler.customize

let random =
  Dream__cipher.Random.random

include Dream__pure.Formats

let test ?(prefix = "") handler request =
  let app =
    content_length
    @@ assign_request_id
    @@ chop_site_prefix prefix
    @@ handler
  in

  Lwt_main.run (app request)

let log =
  Dream__middleware.Log.convenience_log

include Dream__middleware.Tag

let now () = Ptime.to_float_s (Ptime.v (Ptime_clock.now_d_ps ()))

let form = form ~now
let multipart = multipart ~now
let csrf_token = csrf_token ~now
let verify_csrf_token = verify_csrf_token ~now
let form_tag = form_tag ~now
