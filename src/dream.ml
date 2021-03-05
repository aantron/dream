open Dream_pure
include Dream_

let identity handler request =
  handler request

let start handler request =
  handler request

let request_id =
  Request_id.assign

let logger =
  Log.logger

let default_log =
  Log.source (Logs.Src.name Logs.default)

let content_length =
  Content_length.assign

let synchronous next_handler request =
  Lwt.return (next_handler request)

let log =
  Log.convenience_log

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

module Request_id = Request_id
module Log = Log

open Dream_http

type error = Http.error
type error_handler = Http.error_handler
let serve = Http.serve
let run = Http.run
