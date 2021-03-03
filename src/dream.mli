(**/**)
type incoming
type outgoing
(**/**)

type _ message
type request = incoming message
type response = outgoing message

type handler = request -> response Lwt.t
type middleware = handler -> handler

(* TODO Hide all these in a module and group them by category. *)
type status = [
   | `OK
]

val response :
  ?version:int * int ->
  ?status:status ->
  ?reason:string ->
  unit ->
    response

val headers : _ message -> (string * string) list

val status : response -> status

type method_ = [
   | `GET
   | `POST
   | `PUT
   | `DELETE
   | `HEAD
   | `CONNECT
   | `OPTIONS
   | `TRACE
   | `Other of string
]

(* type headers *)
(* TODO LATER Helpers for working on header sets separately. Probably in a
   module Headers. *)
(* type body *)

(* TODO Introduce contexts that are created for each server (or can be shared?).
   These will also help with mocking for testing. *)

[@@@ocaml.warning "-49"]

module Httpaf = Dream_httpaf

(**/**)

val internal_create_request :
  client:string ->
  method_:method_ ->
  target:string ->
  version:int * int ->
  headers:(string * string) list ->
    request
[@@ocaml.deprecated "Internal function. The signature may change."]
