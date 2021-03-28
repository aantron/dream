(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Method_and_status =
struct
  include Dream__pure.Method
  include Dream__pure.Status
end

include Dream__pure.Inmost

(* Eliminate optional arguments from the public interface for now. *)
let next ~bigstring ~close ~exn request =
  next ~bigstring ~close ~exn request

include Dream__middleware.Log
include Dream__middleware.Echo

let logger =
  Dream__middleware.Log.logger

let default_log =
  Dream__middleware.Log.sub_log (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

include Dream__middleware.Router
include Dream__middleware.Static

include Dream__middleware.Session.Exported_defaults

(* include Dream__middleware.Json *)
include Dream__middleware.Form
include Dream__middleware.Upload
include Dream__middleware.Csrf
module Tag = Dream__middleware.Tag

let content_length =
  Dream__middleware.Content_length.content_length

include Dream__graphql.Graphql

include Dream__middleware.Error
include Dream__http.Http

include Dream__middleware.Catch
include Dream__middleware.Request_id
include Dream__middleware.Site_prefix

let error_template =
  Dream__http.Error_handler.customize

let random =
  Dream__pure.Random.random

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
