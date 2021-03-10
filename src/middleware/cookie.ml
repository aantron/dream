(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost

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
let parse_cookie s =
  let pairs =
    s
    |> String.split_on_char ';'
    |> List.map (String.split_on_char '=')
  in

  pairs |> List.fold_left (fun pairs -> function
    | [name; value] -> (String.trim name, String.trim value)::pairs
    | _ -> pairs) []

(* TODO LATER Optimize by caching the parsed cookies in a local key. *)
(* TODO LATER: API: Dream.cookie : string -> request -> string, cookie-option...
   the thing with cookies is that they have a high likelihood of being absent. *)
(* TODO LATER Can decide whether to accept multiple Cookie: headers based on
   request version. But that would entail an actual middleware - is that worth
   it? *)
(* TODO LATER Also not efficient, at all. Need faster parser + the cache. *)
(* TODO DOC Using only raw cookies. *)
(* TODO However, is it best to URL-encode cookies by default, and provide a
   variable for opting out? *)
let cookies request =
  request
  |> Dream.headers "Cookie"
  |> List.map parse_cookie
  |> List.flatten

let cookie name request =
  snd (cookies request |> List.find (fun (name', _) -> name' = name))

let cookie_option name request =
  try Some (cookie name request)
  with Not_found -> None

(* TODO LATER Default encoding. *)
let add_set_cookie name value response =
  Dream.add_header "Set-Cookie" (Printf.sprintf "%s=%s" name value) response

(* TODO LATER Good defaults for path; taking the path from a request; middleware
   for site-wide cookies during prototyping. Needs prefix middleware in place
   first. *)
