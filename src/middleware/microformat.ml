(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Web microformats and encoding. *)

(* TODO DOC Recommend direct use of Base64 library for more options. *)
let base64url text =
  Base64.encode_string ~alphabet:Base64.uri_safe_alphabet text

(* TODO https://www.ietf.org/rfc/rfc4648.txt *)
(* TODO LATER Decoder also. *)
(* TODO LATER Once there are enough microformats, make sure to give everything
   consistent naming to minimize cognitive load. Like X and from_X. *)

(* TODO Move cookie decoding to here. *)

(* TODO Name? *)
(* TODO Not efficient or fully correct (I think). *)
(* TODO Urldecode each thing. *)
(* TODO Name is a bit confusing. *)
let from_form_urlencoded text =
  text
  |> String.split_on_char '&'
  |> List.map (String.split_on_char '=')
  |> List.fold_left (fun pairs -> function
    | [name; value] -> (Uri.pct_decode name, Uri.pct_decode value)::pairs
    | _ -> pairs) []

(* TODO Rename this module. *)
