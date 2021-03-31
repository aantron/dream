(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* http://www.lastbarrier.com/public-claims-and-how-to-validate-a-jwt/ *)
(* https://jwt.io/ *)

module Dream = Dream__pure.Inmost

(* TODO Switch to the new cryptography binding, and eliminate jwt dep. *)

(* TODO LATER The crypto situation in OCaml seems a bit sad; it seems necessary
   to depend on gmp etc. Is this in any way avoidable? *)
(* TODO LATER Perhaps jose + mirage-crypto can solve this. Looks like it needs
   an opam release. *)

(* The current version of the Dream CSRF token puts a hash of the session ID
   into the plaintext portion of a signed JWT, and compares session hashes. The
   hash function must therefore be (relatively?) secure against collision
   attacks.

   A future implementation is likely to encrypt the token, including the
   session ID, instead, in which case it may e possible to avoid hashing it. *)
(* TODO Generalize the session accessor so that this CSRF token generator can
   work with community session managers. *)
let hash_session request =
  request
  |> Session.Exported_defaults.session_key
  |> Digestif.SHA256.digest_string
  |> Digestif.SHA256.to_raw_string
  |> Dream__pure.Formats.to_base64url

(* TODO Encrypt tokens for some security by obscurity? *)

(* TODO Make the expiration configurable. In particular, AJAX CSRF tokens
   may need longer expirations... OTOH maybe not, as they can be refreshed. *)

let default_valid_for =
  60. *. 60.

let csrf_token ?(valid_for = default_valid_for) request =
  let secret = Dream.secret (Dream.app request) in
  let session_hash = hash_session request in
  let now = Unix.gettimeofday () in

  let payload = [
    "session", session_hash;
    "time", Printf.sprintf "%.0f" (now +. valid_for);
  ] in

  Jwto.encode Jwto.HS256 secret payload |> Result.get_ok
  (* TODO Can this fail? *)
  (* |> Lwt.return *)

let field_name =
  "dream.csrf"

let log =
  Log.sub_log field_name

type csrf_result = [
  | `Ok
  | `Expired of float
  | `Wrong_session
  | `Invalid
]

let verify_csrf_token token request =
  let secret = Dream.secret (Dream.app request) in

  begin match Jwto.decode_and_verify secret token with
  | Error _ ->
    log.warning (fun log -> log ~request "CSRF token invalid");
    `Invalid

  | Ok decoded_token ->
    match Jwto.get_payload decoded_token with
    | ["session", token_session_hash; "time", expires_at] ->

      begin match Float.of_string_opt expires_at with
      | None ->
        log.warning (fun log -> log ~request "CSRF token time field invalid");
        `Invalid

      | Some expires_at ->

        let real_session_hash = hash_session request in
        if token_session_hash <> real_session_hash then begin
          log.warning (fun log -> log ~request
            "CSRF token not for this session");
          `Wrong_session
        end

        else
          let now = Unix.gettimeofday () in
          if expires_at > now then
            `Ok
          else begin
            log.warning (fun log -> log ~request "CSRF token expired");
            `Expired expires_at
          end
      end

    | _ ->
      log.warning (fun log -> log ~request "CSRF token payload invalid");
      `Invalid
  end
  |> Lwt.return
