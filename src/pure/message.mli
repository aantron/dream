(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Note: this is not a stable API! *)



type client
type server
type 'a message
type request = client message
type response = server message

type 'a promise = 'a Lwt.t
type handler = request -> response
type middleware = handler -> handler



val request :
  ?method_:[< Method.method_ ] ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  Stream.stream ->
  Stream.stream ->
    request

val method_ : request -> Method.method_
val target : request -> string
val version : request -> int * int
val set_method_ : request -> [< Method.method_ ] -> unit
val set_target : request -> string -> unit
val set_version : request -> int * int -> unit



val response :
  ?status:[< Status.status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  Stream.stream ->
  Stream.stream ->
    response

val status : response -> Status.status



val header : 'a message -> string -> string option
val headers : 'a message -> string -> string list
val all_headers : 'a message -> (string * string) list
val has_header : 'a message -> string -> bool
val add_header : 'a message -> string -> string -> unit
val drop_header : 'a message -> string -> unit
val set_header : 'a message -> string -> string -> unit
val set_all_headers : 'a message -> (string * string) list -> unit
val sort_headers : (string * string) list -> (string * string) list



val body : 'a message -> string promise
val set_body : 'a message -> string -> unit
val read : 'a message -> string option promise
val write : ?kind:[< `Text | `Binary ] -> response -> string -> unit promise
val flush : response -> unit promise
val close : ?code:int -> 'a message -> unit promise
val client_stream : 'a message -> Stream.stream
val server_stream : 'a message -> Stream.stream
val set_client_stream : 'a message -> Stream.stream -> unit
val set_server_stream : 'a message -> Stream.stream -> unit



val no_middleware : middleware
val pipeline : middleware list -> middleware



type 'a field
val new_field : ?name:string -> ?show_value:('a -> string) -> unit -> 'a field
val field : 'b message -> 'a field -> 'a option
val set_field : 'b message -> 'a field -> 'a -> unit
val fold_fields : (string -> string -> 'a -> 'a) -> 'a -> 'b message -> 'a
