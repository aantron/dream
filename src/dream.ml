include Dream_pure.Inmost

let cookies = Dream_middleware.Cookie.cookies
let cookie = Dream_middleware.Cookie.cookie
let cookie_option = Dream_middleware.Cookie.cookie_option
let add_set_cookie = Dream_middleware.Cookie.add_set_cookie

let identity handler request =
  handler request

let start handler request =
  handler request

let request_id =
  Dream_middleware_built_in.Request_id.assign

let logger =
  Dream_middleware.Log.logger

let catch =
  Dream_middleware.Catch.catch

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

module Request_id = Dream_middleware_built_in.Request_id
module Log = Dream_middleware.Log

type route = Dream_middleware.Router.route

(* TODO Rename the underlying value. *)
let crumb =
  Dream_middleware.Router.path_parameter

let router =
  Dream_middleware.Router.router

let get =
  Dream_middleware.Router.get

let post =
  Dream_middleware.Router.post

let apply =
  Dream_middleware.Router.apply

type session =
  Dream_middleware.Session.t

let sessions =
  Dream_middleware.Session.check

let session =
  Dream_middleware.Session.get

let csrf =
  Dream_middleware.Csrf.verify

let form =
  Dream_middleware.Form.urlencoded

let form_get =
  Dream_middleware.Form.get

type error = Dream_http.Http.error
type error_handler = Dream_http.Http.error_handler
let serve = Dream_http.Http.serve
let run = Dream_http.Http.run

let random =
  Dream_middleware.Random.random

let base64url =
  Dream_middleware.Microformat.base64url
