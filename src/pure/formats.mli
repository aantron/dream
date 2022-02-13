(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Note: this is not a stable API! *)



val html_escape : string -> string
val to_base64url : string -> string
val from_base64url : string -> string option
val to_percent_encoded : ?international:bool -> string -> string
val from_percent_encoded : string -> string
val to_form_urlencoded : (string * string) list -> string
val from_form_urlencoded : string -> (string * string) list
val from_cookie : string -> (string * string) list
val split_target : string -> string * string
val from_path : string -> string list
val to_path : ?relative:bool -> ?international:bool -> string list -> string
val drop_trailing_slash : string list -> string list
val text_html : string
val application_json : string

val to_set_cookie :
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[ `Strict | `Lax | `None ] ->
    string -> string -> string
