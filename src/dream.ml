open Dream_pure
include Dream_

let identity handler request =
  handler request

let start handler request =
  handler request

let request_id =
  Request_id.assign

let log =
  Log.log_traffic

let default_log =
  Log.source (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

module Request_id = Request_id
module Log = Log

open Dream_http

type error_handler = Http.error_handler
let serve = Http.serve
let run = Http.run
