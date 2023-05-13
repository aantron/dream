(* From
   https://github.com/lyrm/ocaml-httpadapter/blob/master/src-httpaf/accept.ml

   Copyright (c) 2019 Carine Morel <carine@tarides.com>

   Permission to use, copy, modify, and distribute this software for any purpose
   with or without fee is hereby granted, provided that the above copyright
   notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
   REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
   AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
   INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
   LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
   OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
   PERFORMANCE OF THIS SOFTWARE. *)

open Angstrom
open Printf

type encoding =
  | Encoding of string
  | Gzip
  | Compress
  | Deflate
  | Identity
  | Any

type p = string * string
type q = int
type 'a qlist = (q * 'a) list

(** Lexer *)
let is_space = function
  | ' ' | '\t' -> true
  | _ -> false

let is_token = function
  | '\000' .. '\031'
  | '\127'
  | ')'
  | '('
  | '<'
  | '>'
  | '@'
  | ','
  | ';'
  | ':'
  | '"'
  | '/'
  | '['
  | ']'
  | '?'
  | '='
  | '{'
  | '}'
  | ' ' -> false
  | _s -> true

let ows = skip is_space <|> return ()
let token = take_while1 is_token
let sep_by1_comma value_parser = sep_by1 (char ',') value_parser <* end_of_input

let eval_parser parser default_value = function
  | None -> [(1000, default_value)]
  | Some str -> (
    match parse_string ~consume:Angstrom.Consume.All parser str with
    | Ok v -> v
    | Error msg -> failwith msg)

(** Parser for header parameters like defined in rfc
       https://tools.ietf.org/html/rfc7231#section-5.3.2 *)
type param =
  | Q of int
  | Kv of p

let q_of_string s = truncate (1000. *. float_of_string s)

(* More restrictive than cohttp counterpart *)
let qs = char '"' *> token <* char '"'

(* a header parameter can be : OWS ; OWS q=[value] OWS ; OWS [name]=[value] OWS
   ; OWS [name]="[value]" *)
let param : param t =
  ows
  *> char ';'
  *> ows
  *> (* OWS ; OWS q=[value] OWS ; OWS [name]=[value]*)
  (lift2
     (fun n v -> if n = "q" then Q (q_of_string v) else Kv (n, v))
     token
     (char '=' *> token)
  <|> (* OWS ; OWS [name]="[value]" *)
  lift2 (fun n v -> Kv (n, v)) token (char '=' *> qs))

let params = many param

let rec get_q params =
  match params with
  | [] -> 1000
  | Q q :: _ -> q
  | _ :: r -> get_q r

(** Parser for values of Accept-encoding header. Example: Accept-Encoding:
       compress, gzip Accept-Encoding: Accept-Encoding: * Accept-Encoding:
       compress;q=0.5, gzip;q=1.0 Accept-Encoding: gzip;q=1.0, identity; q=0.5,
       *;q=0 *)
let encoding_value_parser =
  ows
  *> (char '*' *> return (Any : encoding)
     <|> lift
           (fun s ->
             match String.lowercase_ascii s with
             | "gzip" -> Gzip
             | "compress" -> Compress
             | "deflate" -> Deflate
             | "identity" -> Identity
             | enc -> Encoding enc)
           token)

let encoding_parser =
  lift2 (fun value q -> (q, value)) encoding_value_parser (lift get_q params)

let encodings_parser = sep_by1_comma encoding_parser
let encodings = eval_parser encodings_parser Any

(** Other functions (from Cohttp.Accept) *)
let rec string_of_pl = function
  | [] -> ""
  | (k, v) :: r ->
    let e = Stringext.quote v in
    if v = e then
      sprintf ";%s=%s%s" k v (string_of_pl r)
    else
      sprintf ";%s=\"%s\"%s" k e (string_of_pl r)

let string_of_q = function
  | q when q < 0 -> invalid_arg (Printf.sprintf "qvalue %d must be positive" q)
  | q when q > 1000 ->
    invalid_arg (Printf.sprintf "qvalue %d must be less than 1000" q)
  | 1000 -> "1"
  | q -> Printf.sprintf "0.%03d" q

let accept_el ?q el pl =
  match q with
  | Some q -> sprintf "%s;q=%s%s" el (string_of_q q) (string_of_pl pl)
  | None -> el

let string_of_encoding ?q = function
  | Encoding e -> accept_el ?q e []
  | Gzip -> accept_el ?q "gzip" []
  | Compress -> accept_el ?q "compress" []
  | Deflate -> accept_el ?q "deflate" []
  | Identity -> accept_el ?q "identity" []
  | Any -> accept_el ?q "*" []

let string_of_list s_of_el =
  let rec aux s = function
    | [(q, el)] -> s ^ s_of_el el q
    | [] -> s
    | (q, el) :: r -> aux (s ^ s_of_el el q ^ ",") r
  in
  aux ""

let string_of_encodings = string_of_list (fun el q -> string_of_encoding ~q el)

let qsort l =
  let compare ((i : int), _) (i', _) = compare i' i in
  List.stable_sort compare l
