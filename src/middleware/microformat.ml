(* Web microformats and encoding. *)

(* TODO DOC Recommend direct use of Base64 library for more options. *)
let base64url text =
  Base64.encode_string ~alphabet:Base64.uri_safe_alphabet text

(* TODO https://www.ietf.org/rfc/rfc4648.txt *)
(* TODO LATER Decoder also. *)
(* TODO LATER Once there are enough microformats, make sure to give everything
   consistent naming to minimize cognitive load. Like X and from_X. *)
