(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Formats = Dream_pure.Formats
module Message = Dream_pure.Message



let log =
  Log.sub_log "dream.form"

let sort form =
  List.stable_sort (fun (key, _) (key', _) -> String.compare key key') form

type 'a form_result = [
  | `Ok            of 'a
  | `Expired       of 'a * float
  | `Wrong_session of 'a
  | `Invalid_token of 'a
  | `Missing_token of 'a
  | `Many_tokens   of 'a
  | `Wrong_content_type
]

let sort_and_check_form ~now to_value form request =
  let csrf_token, form =
    List.partition (fun (name, _) -> name = Csrf.field_name) form in
  let form = sort form in

  match csrf_token with
  | [_, value] ->
    begin match Csrf.verify_csrf_token ~now request (to_value value) with
    | `Ok ->
      `Ok form

    | `Expired time ->
      `Expired (form, time)

    | `Wrong_session ->
      `Wrong_session form

    | `Invalid ->
      `Invalid_token form
    end

  | [] ->
    log.warning (fun log -> log ~request "CSRF token missing");
    `Missing_token form

  | _::_::_ ->
    log.warning (fun log -> log ~request "CSRF token duplicated");
    `Many_tokens form

let wrong_content_type request =
  log.warning (fun log -> log ~request
    "Content-Type not 'application/x-www-form-urlencoded'");
  `Wrong_content_type

let form ?(csrf = true) ~now request =
  match Message.header request "Content-Type" with
  | None ->
    wrong_content_type request
  | Some content_type ->
    match String.split_on_char ';' content_type with
    | "application/x-www-form-urlencoded"::_ ->
      let body = Message.body request in
      let form = Formats.from_form_urlencoded body in
      if csrf then
        sort_and_check_form ~now (fun string -> string) form request
      else
        `Ok (sort form)
    | _ ->
      wrong_content_type request
