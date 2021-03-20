(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO DOC Recommend direct use of Base64 library for more options. *)
let to_base64url text =
  Base64.encode_string ~pad:false ~alphabet:Base64.uri_safe_alphabet text

let from_base64url text =
  match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet text with
  | Error (`Msg string) -> Error string
  | Ok _ as ok -> ok

(* TODO https://www.ietf.org/rfc/rfc4648.txt *)

(* TODO Not quite a middleware. *)
(* TODO DOC We allow multiple headers sent by the client, to support HTTP/2. *)

(* TODO DOC
   cookie-header = "Cookie:" OWS cookie-string OWS
   cookie-string = cookie-pair *( ";" SP cookie-pair )
 cookie-pair       = cookie-name "=" cookie-value
 cookie-name       = token
 cookie-value      = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
 cookie-octet      = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
                       ; US-ASCII characters excluding CTLs,
                       ; whitespace DQUOTE, comma, semicolon,
                       ; and backslash
https://www.ietf.org/rfc/rfc6265.txt

   The OWS (optional whitespace) rule is used where zero or more linear
   whitespace characters MAY appear:

   OWS            = *( [ obs-fold ] WSP )
                    ; "optional" whitespace
   obs-fold       = CRLF

   OWS SHOULD either not be produced or be produced as a single SP
   character.
 token             = <token, defined in [RFC2616], Section 2.2>

  TODO Should make a web microformats library.
       token          = 1*<any CHAR except CTLs or separators>

TOOD LATER Write a "proper" parser, probably factor it out, too. Hoard all the
relevant RFCs in doc/rfc
TODO This is just an initial parser. It is neither fast nor correct.
TODO This other library should include fold-style interface for reducing
allocations.
*)
(* TODO Difference between "cookie encoding" and "cookie-safe encoding"!!!! *)
let from_cookie_encoded s =
  let pairs =
    s
    |> String.split_on_char ';'
    |> List.map (String.split_on_char '=')
  in

  pairs |> List.fold_left (fun pairs -> function
    | [name; value] -> (String.trim name, String.trim value)::pairs
    | _ -> pairs) []

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

(* Split a target into a path component list and a query string; percent-decode
   path components along the way. The query string is not touched. It is parsed
   lazily by a separate parser. Empty paths ("") become empty component lists.
   The root ("/") becomes [""]. Trailing slashes result in "" as the last
   component of the list.

   This parser creates a considerable amount of intermediate values, all of
   which can be eliminated by optimization if the need arises. *)
let parse_target target =
  let path, query =
    match String.index target '?' with
    | exception Not_found -> target, ""
    | question_index ->
      String.sub target
        0 question_index,
      String.sub target
        (question_index + 1) (String.length target - question_index - 1)
  in

  (* Get rid of all empty components except for the last. Not tail-recursive -
     does it need to be? *)
  let rec filter_components = function
    | [] -> []
    | [""] as components -> components
    | ""::components -> filter_components components
    | component::components -> component::(filter_components components)
  in

  let components =
    if path = "" then
      []
    else
      String.split_on_char '/' path
      |> filter_components
      |> List.map Uri.pct_decode
  in

  components, query

(* Not tail-recursive. Only called on the site prefix and route fragments during
   app setup. *)
let rec trim_empty_trailing_component = function
  | [] -> []
  | [""] -> []
  | component::components ->
    component::(trim_empty_trailing_component components)

let make_path path =
  "/" ^ (String.concat "/" path)
