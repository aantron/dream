(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO Try to erase this file. *)

module Dream = Dream__pure.Inmost



(* TODO Reorder arguments. *)
val serve :
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?prefix:string ->
  ?app:Dream.app ->
  ?debug:bool ->
  ?error_handler:Error.error_handler ->
  Dream.handler ->
    unit Lwt.t

val run :
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?prefix:string ->
  ?app:Dream.app ->
  ?debug:bool ->
  ?error_handler:Error.error_handler ->
  ?greeting:bool ->
  ?stop_on_input:bool ->
  ?graceful_stop:bool ->
  Dream.handler ->
    unit
