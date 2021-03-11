(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Dream__pure.Inmost

let cookies = Dream__middleware.Cookie.cookies
let cookie = Dream__middleware.Cookie.cookie
let cookie_option = Dream__middleware.Cookie.cookie_option
let add_set_cookie = Dream__middleware.Cookie.add_set_cookie

let request_id =
  Dream__middleware__built_in.Request_id.assign

let logger =
  Dream__middleware.Log.logger

let catch =
  Dream__middleware.Catch.catch

let content_length =
  Dream__middleware.Content_length.assign

let synchronous next_handler request =
  Lwt.return (next_handler request)

let log =
  Dream__middleware.Log.convenience_log

let default_log =
  Dream__middleware.Log.source (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

module Request_id = Dream__middleware__built_in.Request_id
module Log = Dream__middleware.Log

include Dream__middleware.Router

type session =
  Dream__middleware.Session.t

let sessions =
  Dream__middleware.Session.check

let session =
  Dream__middleware.Session.get

let csrf =
  Dream__middleware.Csrf.verify

let form =
  Dream__middleware.Form.urlencoded

let form_get =
  Dream__middleware.Form.get

type error = Dream__http.Http.error
type error_handler = Dream__http.Http.error_handler
let serve = Dream__http.Http.serve
let run = Dream__http.Http.run

let random =
  Dream__middleware.Random.random

let base64url =
  Dream__pure.Formats.base64url

let test ?(prefix = "") handler request =
  let prefix =
    prefix
    |> Dream__pure.Formats.parse_target
    |> fst
    |> Dream__pure.Formats.trim_empty_trailing_component
  in

  request
  |> with_next_prefix prefix
  |> Dream__middleware__built_in.Built_in.middleware handler
  |> Lwt_main.run

let test_parse_target =
  Dream__pure.Formats.parse_target

let test_internal_prefix =
  internal_prefix

let test_internal_path =
  internal_path

(* let test_parse_route =
  Dream_middleware.Router.parse *)
