(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let log =
  Log.sub_log "dream.form"

let sort form =
  List.stable_sort (fun (key, _) (key', _) -> String.compare key key') form

type form_result = [
  | `Ok            of (string * string) list
  | `Expired       of (string * string) list * float
  | `Wrong_session of (string * string) list * string
  | `Invalid_token of (string * string) list
  | `Missing_token of (string * string) list
  | `Many_tokens   of (string * string) list
  | `Not_form_urlencoded
]

let form request =
  match Dream.header "Content-Type" request with
  | Some "application/x-www-form-urlencoded" ->

    let%lwt body = Dream.body request in

    let form = Dream__pure.Formats.from_form_urlencoded body in
    let csrf_token, form =
      List.partition (fun (name, _) -> name = Csrf.field_name) form in
    let form = sort form in

    begin match csrf_token with
    | [_, value] ->
      begin match%lwt Csrf.verify_csrf_token value request with
      | `Ok ->
        Lwt.return (`Ok form)

      | `Expired time ->
        Lwt.return (`Expired (form, time))

      | `Wrong_session id ->
        Lwt.return (`Wrong_session (form, id))

      | `Invalid ->
        Lwt.return (`Invalid_token form)
      end

    | [] ->
      log.warning (fun log -> log ~request "CSRF token missing");
      Lwt.return (`Missing_token form)

    | _::_::_ ->
      log.warning (fun log -> log ~request "CSRF token duplicated");
      Lwt.return (`Many_tokens form)
    end

  | _ ->
    log.warning (fun log -> log ~request
      "Request Content-Type not application/x-www-form-urlencoded");
    Lwt.return `Not_form_urlencoded
