(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type 'a message

type client
type server

type request = client message
type response = server message

type 'a promise = 'a Lwt.t
type handler = request -> response promise
type middleware = handler -> handler

type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
type stream



type method_ = [
  | `GET
  | `POST
  | `PUT
  | `DELETE
  | `HEAD
  | `CONNECT
  | `OPTIONS
  | `TRACE
  | `PATCH
  | `Method of string
]

val method_to_string : [< method_ ] -> string
val string_to_method : string -> method_
val methods_equal : [< method_ ] -> [< method_ ] -> bool
val normalize_method : [< method_ ] -> method_



type informational = [
  | `Continue
  | `Switching_Protocols
]

type successful = [
  | `OK
  | `Created
  | `Accepted
  | `Non_Authoritative_Information
  | `No_Content
  | `Reset_Content
  | `Partial_Content
]

type redirection = [
  | `Multiple_Choices
  | `Moved_Permanently
  | `Found
  | `See_Other
  | `Not_Modified
  | `Temporary_Redirect
  | `Permanent_Redirect
]

type client_error = [
  | `Bad_Request
  | `Unauthorized
  | `Payment_Required
  | `Forbidden
  | `Not_Found
  | `Method_Not_Allowed
  | `Not_Acceptable
  | `Proxy_Authentication_Required
  | `Request_Timeout
  | `Conflict
  | `Gone
  | `Length_Required
  | `Precondition_Failed
  | `Payload_Too_Large
  | `URI_Too_Long
  | `Unsupported_Media_Type
  | `Range_Not_Satisfiable
  | `Expectation_Failed
  | `Misdirected_Request
  | `Too_Early
  | `Upgrade_Required
  | `Precondition_Required
  | `Too_Many_Requests
  | `Request_Header_Fields_Too_Large
  | `Unavailable_For_Legal_Reasons
]

type server_error = [
  | `Internal_Server_Error
  | `Not_Implemented
  | `Bad_Gateway
  | `Service_Unavailable
  | `Gateway_Timeout
  | `HTTP_Version_Not_Supported
]

type standard_status = [
  | informational
  | successful
  | redirection
  | client_error
  | server_error
]

type status = [
  | standard_status
  | `Status of int
]

val status_to_string : [< status ] -> string
val status_to_reason : [< status ] -> string option
val status_to_int : [< status ] -> int
val int_to_status : int -> status
val is_informational : [< status ] -> bool
val is_successful : [< status ] -> bool
val is_redirection : [< status ] -> bool
val is_client_error : [< status ] -> bool
val is_server_error : [< status ] -> bool
val status_codes_equal : [< status ] -> [< status ] -> bool
val normalize_status : [< status ] -> status



val request :
  ?method_:[< method_ ] ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  stream ->
  stream ->
    request

val method_ : request -> method_
val target : request -> string
val version : request -> int * int
val with_method_ : [< method_ ] -> request -> request
val with_version : int * int -> request -> request



val response :
  ?status:[< status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  stream ->
  stream ->
    response

val status : response -> status



val header : string -> 'a message -> string option
val headers : string -> 'a message -> string list
val all_headers : 'a message -> (string * string) list
val has_header : string -> 'a message -> bool
val add_header : string -> string -> 'a message -> 'a message
val drop_header : string -> 'a message -> 'a message
val with_header : string -> string -> 'a message -> 'a message
val with_all_headers : (string * string) list -> 'a message -> 'a message



val all_cookies : request -> (string * string) list
(* TODO Should become server-side-only. *)



val body : 'a message -> string promise
val with_body : string -> response -> response
val read : request -> string option promise
val with_stream : 'a message -> 'a message
val write : response -> string -> unit promise
val flush : response -> unit promise
val close_stream : response -> unit promise
(* TODO This will need to read different streams depending on whether it is
   passed a request or a response. *)
val client_stream : 'a message -> stream
val server_stream : 'a message -> stream
val with_client_stream : stream -> 'a message -> 'a message
val next :
  stream ->
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  close:(int -> unit) ->
  flush:(unit -> unit) ->
  ping:(buffer -> int -> int -> unit) ->
  pong:(buffer -> int -> int -> unit) ->
    unit
val write_buffer :
  ?offset:int -> ?length:int -> response -> buffer -> unit promise

module Stream :
sig
type reader

type writer

type read =
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  close:(int -> unit) ->
  flush:(unit -> unit) ->
  ping:(buffer -> int -> int -> unit) ->
  pong:(buffer -> int -> int -> unit) ->
    unit
(** A reading function. Awaits the next event on the stream. For each call of a
    reading function, one of the callbacks will eventually be called, according
    to which event occurs next on the stream. *)

type write =
  close:(int -> unit) ->
  (unit -> unit) ->
    unit
(** A writing function. Pushes an event into a stream. May take additional
    arguments before [~ok]. *)

val reader : read:read -> close:(int -> unit) -> reader
(** Creates a read-only stream from the given reader. [~close] is called in
    response to {!Stream.close}. It doesn't need to call {!Stream.close} again
    on the stream. It should be used to free any underlying resources. *)

val empty : reader
(** A read-only stream whose reading function always calls its [~close]
    callback. *)

val string : string -> reader
(** A read-only stream which calls its [~data] callback once with the contents
    of the given string, and then always calls [~close]. *)

val pipe : unit -> reader * writer
(** A stream which matches each call of the reading function to one call of its
    writing functions. For example, calling {!Stream.flush} on a pipe will cause
    the reader to call its [~flush] callback. *)

val writer :
  ready:write ->
  write:(buffer -> int -> int -> bool -> bool -> write) ->
  flush:write ->
  ping:(buffer -> int -> int -> write) ->
  pong:(buffer -> int -> int -> write) ->
  close:(int -> unit) ->
    writer

val no_reader : reader

val no_writer : writer

val stream : reader -> writer -> stream
(* TODO Consider tupling the arguments, as that will make it easier to pass the
   result of Stream.pipe. *)

val close : stream -> int -> unit
(** Closes the given stream. Causes a pending reader or writer to call its
    [~close] callback. *)

val read : stream -> read
(** Awaits the next stream event. See {!Stream.type-read}. *)

val read_convenience : stream -> string option promise
(** A wrapper around {!Stream.read} that converts [~data] with content [s] into
    [Some s], and [~close] into [None], and uses them to resolve a promise.
    [~flush] is ignored. *)

val read_until_close : stream -> string promise
(** Reads a stream completely until [~close], and accumulates the data into a
    string. *)

val ready : stream -> write

val write : stream -> buffer -> int -> int -> bool -> bool -> write
(** A writing function that sends a data buffer on the given stream. No more
    writing functions should be called on the stream until this function calls
    [~ok]. The [bool] arguments are whether the message is binary and whether
    the [FIN] flag should be set. They are ignored by non-WebSocket streams.

    Note: [FIN] is provided as part of the write call, rather than being a
    separate stream event (like [flush]), because the WebSocket writer needs to
    immediately know when the last chunk of the last frame in a message is
    provided, to transmit the [FIN] bit. If [FIN] were to be provided as a
    separate event, the WebSocket writer would have to buffer each one chunk, in
    case the next stream event was [FIN], in order to be able to decide whether
    to set the [FIN] bit or not. This is awkward and inefficient, as it
    introduces an unnecessary delay into the writer, as if the next event is not
    [FIN], the next data chunk might take an arbitrary amount of time to be
    generated by the writing user code. *)

val flush : stream -> write
(** A writing function that asks for the given stream to be flushed. The meaning
    of flushing depends on the implementation of the stream. No more writing
    functions should be called on the stream until this function calls [~ok]. *)

val ping : stream -> buffer -> int -> int -> write
(** A writing function that sends a ping event on the given stream. This is only
    meaningful for WebSockets. *)

val pong : stream -> buffer -> int -> int -> write
(** A writing function that sends a pong event on the given stream. This is only
    meaningful for WebSockets. *)
end

(* TODO Remove to server-side code. *)
type multipart_state = {
  mutable state_init : bool;
  mutable name : string option;
  mutable filename : string option;
  mutable stream : (< > * Multipart_form.Header.t * string Lwt_stream.t) Lwt_stream.t;
}

val multipart_state : request -> multipart_state



val no_middleware : middleware
val pipeline : middleware list -> middleware



type websocket = stream
val websocket :
  ?headers:(string * string) list ->
  (websocket -> unit promise) ->
    response promise
val send : ?kind:[< `Text | `Binary ] -> websocket -> string -> unit promise
val receive : websocket -> string option promise
val close_websocket : ?code:int -> websocket -> unit promise
val is_websocket : response -> (websocket -> unit promise) option



type log_level = [
  | `Error
  | `Warning
  | `Info
  | `Debug
]

type error = {
  condition : [
    | `Response of response
    | `String of string
    | `Exn of exn
  ];
  layer : [
    | `App
    | `HTTP
    | `HTTP2
    | `TLS
    | `WebSocket
  ];
  caused_by : [
    | `Server
    | `Client
  ];
  request : request option;
  response : response option;
  client : string option;
  severity : log_level;
  will_send_response : bool;
}

type error_handler = error -> response option promise

val request_from_http :
  method_:method_ ->
  target:string ->
  version:int * int ->
  headers:(string * string) list ->
  stream ->
    request



module Formats :
sig
  val html_escape : string -> string
  val to_base64url : string -> string
  val from_base64url : string -> string option
  val to_percent_encoded : ?international:bool -> string -> string
  val from_percent_encoded : string -> string
  val to_form_urlencoded : (string * string) list -> string
  val from_form_urlencoded : string -> (string * string) list
  val from_cookie : string -> (string * string) list
  val to_set_cookie :
    ?expires:float ->
    ?max_age:float ->
    ?domain:string ->
    ?path:string ->
    ?secure:bool ->
    ?http_only:bool ->
    ?same_site:[ `Strict | `Lax | `None ] ->
      string -> string -> string
  val split_target : string -> string * string
  val from_path : string -> string list
  val to_path : ?relative:bool -> ?international:bool -> string list -> string
  val drop_trailing_slash : string list -> string list
  val make_path : string list -> string
  val text_html : string
  val application_json : string
end



type 'a local
val new_local : ?name:string -> ?show_value:('a -> string) -> unit -> 'a local
val local : 'a local -> 'b message -> 'a option
val with_local : 'a local -> 'a -> 'b message -> 'b message
val fold_locals : (string -> string -> 'a -> 'a) -> 'a -> 'b message -> 'a



(* TODO Delete once requests are mutable. *)
val first : 'a message -> 'a message
val last : 'a message -> 'a message
val sort_headers : (string * string) list -> (string * string) list
