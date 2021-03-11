(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* http://www.lastbarrier.com/public-claims-and-how-to-validate-a-jwt/ *)
(* https://jwt.io/ *)

module Dream =
struct
  include Dream_pure.Inmost
  module Log = Log
  module Session = Session
  (* let add_set_cookie = Cookie.add_set_cookie *)
  let base64url = Dream_pure.Formats.base64url
  let random = Random.random
end

(* module Log = (val Fw.Logger.create_log "mw.csrf" : Fw.Logger.LOG) *)

(* TODO LATER The crypto situation in OCaml seems a bit sad; it seems necessary
   to depend on gmp etc. Is this in any way avoidable? *)
(* TODO LATER Perhaps jose + mirage-crypto can solve this. Looks like it needs
   an opam release. *)

let log =
  Dream.Log.source "dream.csrf"

(* TODO Generate/use real secrets. *)
let secret = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

let hash_session request =
  Dream.base64url
    (Digest.string (Dream.Session.key (Dream.Session.get request)))

(* TODO Use a stronger hash of the session ID. *)
(* TODO Encrypt tokens for some security by obscurity? *)
(* TODO Consider scoping to form. That would allow e.g. using a long-lived token
   for a logout POST form, while shorter-lived tokens are used for other
   interactions. *)

let identify_hash hash =
  String.sub hash 0 3

let token request =
  let hash = hash_session request in
  let tag = Dream.base64url (Dream.random 6) in

  let payload = [
    "id", hash;
    "tag", tag;
    "time", Int64.to_string (Int64.of_float (Unix.time ()));
  ] in

  log.debug (fun m ->
    m ~request "Session %s (hash prefix %s): new CSRF token %s"
      (Session.identify request) (identify_hash hash) tag)
  |> ignore;

  Jwto.encode Jwto.HS256 secret payload |> Result.get_ok
  (* TODO Can this fail? *)

let field = "csrf"

(* TODO Check expiration. *)
(* TODO More graceful handling of bad CSRF, like re-sending the form with
   non-sensitive fields filled in as before. *)
(* TODO Rename m to log in logging. *)

let verify handler request =
  (* let csrf, req = Form.consume field req in *)
  let csrf, request = [[""]], request in
  let valid =
    match csrf with
    | [[token]] ->
      begin match Jwto.decode_and_verify secret token with
      | Ok value ->
        begin match Jwto.get_payload value with
        | ["id", hash; "tag", tag; "time", _] ->
          hash = hash_session request || begin
            log.debug (fun m -> m ~request
              "Session %s (hash prefix %s): got CSRF token %s for %s"
              (Session.identify request) (hash_session request) tag hash);
            log.warning (fun m -> m ~request "CSRF token mismatch");
            false
          end
        | _ ->
          log.warning (fun m -> m ~request "CSRF token: bad payload");
          false
        end
      | _ ->
        log.warning (fun m -> m ~request "CSRF token: invalid");
        false
      end
    | _ ->
      log.warning (fun m ->
        m ~request "CSRF token: missing or multiple values");
      false
  in
  if valid then
    handler request
  else
    Dream.respond ~status:`Bad_request ""
