(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let to_base64url string =
  Base64.encode_string ~pad:false ~alphabet:Base64.uri_safe_alphabet string

let from_base64url string =
  match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet string with
  | Error (`Msg string) -> Error string
  | Ok _ as ok -> ok



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



let to_form_urlencoded dictionary =
  dictionary
  |> List.map (fun (name, value) -> name, [value])
  |> Uri.encoded_of_query

let from_form_urlencoded string =
  string
  |> Uri.query_of_encoded
  |> List.map (fun (name, values) -> name, String.concat "," values)



let from_target string =
  let uri = Uri.of_string string in
  let query =
    match Uri.verbatim_query uri with
    | Some query -> query
    | None -> ""
  in
  Uri.path uri, query

let from_target_path =
  (* Not tail-recursive. *)
  let rec filter_components = function
    | [] -> []
    | [""] as components -> components
    | ""::components -> filter_components components
    | component::components -> component::(filter_components components)
  in

  fun string ->
    let components =
      if string = "" then
        []
      else
        String.split_on_char '/' string
        |> filter_components
        |> List.map Uri.pct_decode
    in

    components

(* Not tail-recursive. Only called on the site prefix and route fragments during
   app setup. *)
let rec drop_empty_trailing_path_component = function
  | [] -> []
  | [""] -> []
  | component::components ->
    component::(drop_empty_trailing_path_component components)

(* TODO Currently used mainly for debugging; needs to be replaced by an escaping
   function. *)
let make_path path =
  "/" ^ (String.concat "/" path)
