(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Dream__pure.Inmost

module Status =
  Dream__pure.Status

(* let all_cookies = Dream__middleware.Cookie.all_cookies *)
(* let cookie = Dream__middleware.Cookie.cookie *)
(* let add_set_cookie = Dream__middleware.Cookie.add_set_cookie *)

include Dream__middleware.Log

let logger =
  Dream__middleware.Log.logger

(* let content_length =
  Dream__middleware.Content_length.assign *)

(* let synchronous next_handler request =
  Lwt.return (next_handler request) *)

let default_log =
  Dream__middleware.Log.sub_log (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

include Dream__middleware.Router

include Dream__middleware.Session.Exported_defaults

type form_error = [
  | `Not_form_urlencoded
  | `CSRF_token_invalid
]

let form =
  Dream__middleware.Form.form

(* let form_get =
  Dream__middleware.Form.get *)

include Dream__http.Error
include Dream__http.Http

let error_template =
  Dream__http.Error_handler.customize

let random =
  Dream__middleware.Random.random

include Dream__pure.Formats

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

let log =
  Dream__middleware.Log.convenience_log
