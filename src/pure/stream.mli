(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
(** Type abbreviation for byte buffers in the C heap. *)

type 'a promise =
  'a Lwt.t
(** Type abbreviation for promises. *)

type stream
(** This module's principal type, the {e stream}.

    Streams are basically just tuples of a reading function and several writing
    functions. In C++ terms, they are vtables. Different stream objects can have
    completely different implementations of these functions. Concrete stream
    constructors, such as {!Stream.empty} and {!Stream.pipe} implement those
    functions in interesting ways.

    There are three main kinds of streams used in Dream:

    - {e Read-only streams} have the reading function implemented, and the
      writers raise exceptions when called. These are typically created by the
      HTTP layer as facades for the underlying HTTP server's request body
      reader.
    - {e Pipes} have their reading function connected to their writing
      functions. Pipes are essentially a synchronization primitive that allows
      one reader to be satisfied by one writer. These are created for responses,
      because responses are created deep in the user's Web application, and the
      HTTP layer reads them later to process the application's writes. Pipes can
      also be created by middlewares that transform messages bodies, such as for
      compression.
    - {e Duplex streams} have the reading function and writing functions
      implemented, but connected to different streams. This is used primarily
      for WebSockets, where writing to the stream causes data to be sent to the
      client, and reading from the stream awaits data to be received from the
      client.

    Streams are asynchronous. Readers and writers expect callbacks, and call
    them when underlying operations complete.

    The entire interface is pull-based for flow control. *)

type read =
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  close:(unit -> unit) ->
  flush:(unit -> unit) ->
  ping:(unit -> unit) ->
  pong:(unit -> unit) ->
    unit
(** A reading function. Awaits the next event on the stream. For each call of a
    reading function, one of the callbacks will eventually be called, according
    to which event occurs next on the stream. *)

type write =
  ok:(unit -> unit) ->
  close:(unit -> unit) ->
    unit
(** A writing function. Pushes an event into a stream. May take additional
    arguments before [~ok]. *)

val read_only : read:read -> close:(unit -> unit) -> stream
(** Creates a read-only stream from the given reader. [~close] is called in
    response to {!Stream.close}. It doesn't need to call {!Stream.close} again
    on the stream. It should be used to free any underlying resources. *)

val empty : stream
(** A read-only stream whose reading function always calls its [~close]
    callback. *)

val string : string -> stream
(** A read-only stream which calls its [~data] callback once with the contents
    of the given string, and then always calls [~close]. *)

val pipe : unit -> stream
(** A stream which matches each call of the reading function to one call of its
    writing functions. For example, calling {!Stream.flush} on a pipe will cause
    the reader to call its [~flush] callback. *)

val duplex : read:stream -> write:stream -> close:(unit -> unit) -> stream
(** A stream whose reading functions behave like [~read], and whose writing
    functions behave like [~write]. *)

val stream :
  read:read ->
  write:(buffer -> int -> int -> bool -> bool -> write) ->
  flush:write ->
  ping:write ->
  pong:write ->
  close:(unit -> unit) ->
    stream
(** A general stream. *)

val close : stream -> unit
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

val write : stream -> buffer -> int -> int -> bool -> bool -> write
(** A writing function that sends a data buffer on the given stream. No more
    writing functions should be called on the stream until this function calls
    [~ok]. The [bool] arguments are whether the message is binary and whether
    the [FIN] flag should be set. They are ignored by non-WebSocket streams. *)

val flush : stream -> write
(** A writing function that asks for the given stream to be flushed. The meaning
    of flushing depends on the implementation of the stream. No more writing
    functions should be called on the stream until this function calls [~ok]. *)

val ping : stream -> write
(** A writing function that sends a ping event on the given stream. This is only
    meaningful for WebSockets. *)

val pong : stream -> write
(** A writing function that sends a pong event on the given stream. This is only
    meaningful for WebSockets. *)
