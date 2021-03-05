include Dream_pure.Dream_

let identity handler request =
  handler request

let start handler request =
  handler request

let request_id =
  Dream_middleware.Request_id.assign

let logger =
  Dream_middleware.Log.logger

let content_length =
  Dream_middleware.Content_length.assign

let synchronous next_handler request =
  Lwt.return (next_handler request)

let log =
  Dream_middleware.Log.convenience_log

let default_log =
  Dream_middleware.Log.source (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

module Request_id = Dream_middleware.Request_id
module Log = Dream_middleware.Log

open Dream_http

type error = Http.error
type error_handler = Http.error_handler
let serve = Http.serve
let run = Http.run
