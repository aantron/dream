(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure
module Cipher = Dream__cipher.Cipher



let field_name =
  "dream.csrf"

let default_valid_for =
  60. *. 60.

let csrf_token ~now ?(valid_for = default_valid_for) request =
  let now = now () in

  `Assoc [
    "session", `String (Session.session_label request);
    "expires_at", `Float (floor (now +. valid_for));
  ]
  |> Yojson.Basic.to_string
  |> Cipher.encrypt ~associated_data:field_name request
  |> Dream_pure.Formats.to_base64url

let log =
  Log.sub_log field_name

type csrf_result = [
  | `Ok
  | `Expired of float
  | `Wrong_session
  | `Invalid
]

let verify_csrf_token ~now request token =
  match Dream_pure.Formats.from_base64url token with
  | None ->
    log.warning (fun log -> log ~request "CSRF token not Base64-encoded");
    `Invalid
  | Some token ->

  match Cipher.decrypt ~associated_data:field_name request token with
  | None ->
    log.warning (fun log -> log ~request "CSRF token could not be verified");
    `Invalid
  | Some token ->

  (* TODO Don't raise exceptions. *)
  match Yojson.Basic.from_string token with
  | `Assoc [
      "session", `String token_session_label;
      "expires_at", (`Float _ | `Int _  as expires_at);
    ] ->

    let expires_at =
      match expires_at with
      | `Float n -> n
      | `Int n -> float_of_int n
    in

    let real_session_label = Session.session_label request in
    if token_session_label <> real_session_label then begin
      log.warning (fun log -> log ~request
        "CSRF token not for this session");
      `Wrong_session
    end
    else
      let now = now () in
      if expires_at > now then
        `Ok
      else begin
        log.warning (fun log -> log ~request "CSRF token expired");
        `Expired expires_at
      end

  | _ | exception _ ->
    log.warning (fun log -> log ~request "CSRF token payload invalid");
    `Invalid
