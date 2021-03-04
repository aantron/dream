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

val method_to_string : method_ -> string

val response :
  ?version:int * int ->
  ?status:status ->
  ?reason:string ->
  ?headers:(string * string) list ->
  unit ->
    response

val client : request -> string
val method_ : request -> method_
val target : request -> string

val headers : _ message -> (string * string) list
val headers_named : string -> _ message -> string list
val header : string -> _ message -> string
val header_option : string -> _ message -> string option

val status : response -> status
val status_to_int : status -> int

val identity : middleware
val start : middleware
val request_id : ?prefix:string -> middleware
val log : middleware

(* val request_id : ?prefix:string -> middleware *)

(* val assign_request_id : ?prefix:string -> middleware
val request_id : request -> string *)

(* module Id  *)

(* type headers *)
(* TODO LATER Helpers for working on header sets separately. Probably in a
   module Headers. *)
(* type body *)

(* TODO Introduce contexts that are created for each server (or can be shared?).
   These will also help with mocking for testing. *)

(* TODO Hide these in a module. *)

type 'a local

val new_local : unit -> 'a local
val local : 'a local -> _ message -> 'a
val local_option : 'a local -> _ message -> 'a option
val set_local : 'a local -> 'b message -> 'a -> 'b message

module Httpaf = Dream_httpaf [@@ocaml.warning "-49"]

module Request_id :
sig
  (* val assign : ?prefix:string -> middleware *)
  val get_option : ?request:request -> unit -> string option
end

(* TODO Dream-level logging functions. *)

type ('a, 'b) log =
  ((?request:request ->
  ('a, Stdlib.Format.formatter, unit, 'b) Stdlib.format4 -> 'a) -> 'b) ->
    unit

module Log :
sig
  type source = {
    error : 'a. ('a, unit) log;
    warning : 'a. ('a, unit) log;
    info : 'a. ('a, unit) log;
    debug : 'a. ('a, unit) log;
  }

  val source : string -> source

  type level = [
    | `Error
    | `Warning
    | `Info
    | `Debug
  ]

  val initialize : ?backtraces:bool -> ?level:level -> enable:bool -> unit

  val iter_backtrace : (string -> unit) -> string -> unit
end

(* TODO Try to unwrap this module. *)
(* module App :
sig
  type t
  val create : unit -> t

  (* type 'a value

  val value : (unit -> 'a) -> 'a value
  val get : 'a value -> request -> 'a *)
end *)

type app
val new_app : unit -> app

type 'a global

val new_global : initializer_:(unit -> 'a) -> 'a global
val global : 'a global -> request -> 'a

(**/**)

(* TODO DOC The app is just obtained by calling App.create () and holding one
   reference per one server. *)
val internal_create_request :
  app:app ->
  client:string ->
  method_:method_ ->
  target:string ->
  version:int * int ->
  headers:(string * string) list ->
  (* app_scope:(Dream_hmap ) ->1 *)
    request
[@@ocaml.deprecated "Internal function. The signature may change."]

(* TODO DOC Give people a tip: a basic response needs either content-length or
   connection: close. *)
