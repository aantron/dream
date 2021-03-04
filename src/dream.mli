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

val body : request -> string Lwt.t

(* TODO Need to expose the bigstring type eventually. *)
(* TODO Reconsider order of arguments. *)
val set_body_stream : response -> ((string option -> unit) -> unit) -> response
val set_body : response -> string -> response

val identity : middleware
val start : middleware
val request_id : ?prefix:string -> middleware
val log : middleware

type 'a local

(* TODO Reconsider order of arguments in set_local based on usage. *)
val new_local : unit -> 'a local
val local : 'a local -> _ message -> 'a
val local_option : 'a local -> _ message -> 'a option
val set_local : 'a local -> 'b message -> 'a -> 'b message

(* module Httpaf = Dream_httpaf [@@ocaml.warning "-49"] *)

module Request_id :
sig
  val get_option : ?request:request -> unit -> string option
end

type ('a, 'b) log =
  ((?request:request ->
  ('a, Stdlib.Format.formatter, unit, 'b) Stdlib.format4 -> 'a) -> 'b) ->
    unit

val error : ('a, unit) log
val warning : ('a, unit) log
val info : ('a, unit) log
val debug : ('a, unit) log

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

type app
val app : unit -> app

type 'a global

val new_global : initializer_:(unit -> 'a) -> 'a global
val global : 'a global -> request -> 'a

type error_handler =
  Unix.sockaddr ->
  [ `Bad_request | `Bad_gateway | `Internal_server_error | `Exn of exn ] ->
    response Lwt.t

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?app:app ->
  ?error_handler:error_handler ->
  handler ->
    unit Lwt.t

val run :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?app:app ->
  ?error_handler:error_handler ->
  handler ->
    unit

(* TODO Change the error type - replace Bad_gateway and Internal_server_error by
   Bad_response. *)

(* TODO DOC that [stop] only stops the server listening - requests already
   in the server can continue executing. *)
(* TODO DOC Can probably also get `Exn upon failure to stream the body. *)
(* TODO DOC `Bad_gateway and `Internal_server_error occur when the application
   returns a negative content-length, or no content-length when one is
   required. *)
(* TODO DOC Can't even define the response type fully.. or can we? Can just
   reuse the Dream response, but note that the status will be ignored. *)
(* TODO DOC Figure out the behavior of various strings one could pass for the
   interface and DOCUMENT. *)
(* TODO DOC What happens if the error handler also raises an exception? *)
(* TODO DOC Placate the user: the error handler is generally not necessary. *)

(**/**)

(* type bigstring =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t *)

(* TODO DOC The app is just obtained by calling App.create () and holding one
   reference per one server. *)
(* val internal_create_request :
  app:app ->
  client:string ->
  method_:method_ ->
  target:string ->
  version:int * int ->
  headers:(string * string) list ->
  body_stream:((bigstring option -> unit) -> unit) ->
    request
[@@ocaml.deprecated "Internal function. The signature may change."]

val internal_body_stream : response -> ((string option -> unit) -> unit)
[@@ocaml.deprecated "Internal function. The signature may change."] *)

(* TODO DOC Give people a tip: a basic response needs either content-length or
   connection: close. *)
