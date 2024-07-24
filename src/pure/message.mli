(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Note: this is not a stable API! *)



type client
type server
type 'a message
type request = client message
type response = server message

type handler = request -> response
type middleware = handler -> handler



val request :
  ?method_:[< Method.method_ ] ->
  ?target:string ->
  ?headers:(string * string) list ->
  Stream.stream ->
  Stream.stream ->
    request

val method_ : request -> Method.method_
val target : request -> string
val set_method_ : request -> [< Method.method_ ] -> unit
val set_target : request -> string -> unit



val response :
  ?status:[< Status.status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  Stream.stream ->
  Stream.stream ->
    response

val status : response -> Status.status
val set_status : response -> Status.status -> unit



val header : 'a message -> string -> string option
val headers : 'a message -> string -> string list
val all_headers : 'a message -> (string * string) list
val has_header : 'a message -> string -> bool
val add_header : 'a message -> string -> string -> unit
val drop_header : 'a message -> string -> unit
val set_header : 'a message -> string -> string -> unit
val set_all_headers : 'a message -> (string * string) list -> unit
val sort_headers : (string * string) list -> (string * string) list
val lowercase_headers : 'a message -> unit



val body : 'a message -> string
val set_body : 'a message -> string -> unit
val set_content_length_headers : 'a message -> unit
val drop_content_length_headers : 'a message -> unit



val read : Stream.stream -> string option
val write : Stream.stream -> string -> unit
val flush : Stream.stream -> unit
val close : Stream.stream -> unit
val client_stream : 'a message -> Stream.stream
val server_stream : 'a message -> Stream.stream
val set_client_stream : 'a message -> Stream.stream -> unit
val set_server_stream : 'a message -> Stream.stream -> unit



val create_websocket : response -> (Stream.stream * Stream.stream)
val get_websocket : response -> (Stream.stream * Stream.stream) option
val close_websocket : ?code:int -> Stream.stream * Stream.stream -> unit

type text_or_binary = [
  | `Text
  | `Binary
]

type end_of_message = [
  | `End_of_message
  | `Continues
]

(* TODO This also needs message length limits. *)
val receive : Stream.stream -> string option
val receive_fragment :
  Stream.stream -> (string * text_or_binary * end_of_message) option
val send :
  ?text_or_binary:[< text_or_binary ] ->
  ?end_of_message:[< end_of_message ] ->
  Stream.stream ->
  string ->
    unit



val no_middleware : middleware
val pipeline : middleware list -> middleware



type 'a field
val new_field : ?name:string -> ?show_value:('a -> string) -> unit -> 'a field
val field : 'b message -> 'a field -> 'a option
val set_field : 'b message -> 'a field -> 'a -> unit
val fold_fields : (string -> string -> 'a -> 'a) -> 'a -> 'b message -> 'a
