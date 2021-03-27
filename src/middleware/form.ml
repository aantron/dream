(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let log =
  Log.sub_log "dream.form"

let sort form =
  List.stable_sort (fun (key, _) (key', _) -> String.compare key key') form

type form = [
  | `Ok            of (string * string) list
  | `Expired       of (string * string) list * int64
  | `Wrong_session of (string * string) list * string
  | `Invalid_token of (string * string) list
  | `Missing_token of (string * string) list
  | `Many_tokens   of (string * string) list
  | `Not_form_urlencoded
]

let form request =
  let open Lwt.Infix in

  match Dream.header "Content-Type" request with
  | Some "application/x-www-form-urlencoded" ->

    Dream.body request
    >>= fun body ->

    let form = Dream__pure.Formats.from_form_urlencoded body in
    let csrf_token, form =
      List.partition (fun (name, _) -> name = Csrf.field_name) form in
    let form = sort form in

    begin match csrf_token with
    | [_, value] ->
      Csrf.verify_csrf_token value request
      >>= fun csrf_result ->

      begin match csrf_result with
      | `Ok ->
        Lwt.return (`Ok form)

      | `Expired time ->
        log.warning (fun log -> log ~request "CSRF token expired");
        Lwt.return (`Expired (form, time))

      | `Wrong_session id ->
        log.warning (fun log -> log ~request "CSRF token not for this session");
        Lwt.return (`Wrong_session (form, id))

      (* TODO Note in docs that the token may be invalid due to key rotation. *)
      | `Invalid ->
        log.warning (fun log -> log ~request "CSRF token invalid");
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
