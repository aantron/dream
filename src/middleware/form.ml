(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let log =
  Log.sub_log "dream.form"

let sort form =
  List.stable_sort (fun (key, _) (key', _) -> String.compare key key') form

(* TODO Custom CSRF checker or session implementation. *)

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
      begin match Csrf.verify value request with
      | `Ok ->
        Lwt.return (`Ok form)

      | `Expired time ->
        log.warning (fun log -> log ~request "CSRF token expired");
        Lwt.return (`Expired (form, time))

      | `Wrong_session id ->
        log.warning (fun log -> log ~request "CSRF token not for this session");
        Lwt.return (`Wrong_session (form, id))

      | `Invalid_token ->
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

(* TODO Add built-in Content-Type thing. *)
(* TODO Provide well-known Content-Types as predefined strings. *)
(* let urlencoded handler request =
  let open Lwt.Infix in

  match Dream.header "Content-Type" request with
  | Some "application/x-www-form-urlencoded" ->
    Dream.body request >>= fun body ->
    let form = sort (Dream.from_form_urlencoded body) in
    Dream.with_local key form request
    |> handler
  | content_type ->
    log.warning (fun m -> m ~request
      "Bad Content-Type '%s'" (Option.value content_type ~default:""));
    (* TODO Need a convenience function for generating a bad request. *)
    Dream.respond ~status:`Bad_Request ""

(* TODO Use the optional. *)
let get request =
  Dream.local key request |> Option.get
  (* try
    Opium.Context.find_exn key req.env
  with exn ->
    Middleware.missing req name;
    raise exn *)

let consume field request =
  let form = get request in
  let matching, rest =
    List.partition (fun (field', _) -> field' = field) form in
  let matching = List.map snd matching in
  matching, Dream.with_local key rest request *)
