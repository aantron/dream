(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type 'a promise =
  'a Lwt.t

type stream

type read =
  data:(buffer -> int -> int -> unit) ->
  close:(unit -> unit) ->
  flush:(unit -> unit) ->
  exn:(exn -> unit) ->
    unit

val read_only : read:read -> close:(unit -> unit) -> stream
val empty : stream
val string : string -> stream
val pipe : unit -> stream

val read : stream -> read
val read_convenience : stream -> string option promise
val read_until_close : stream -> string promise

(* TODO Wrong signature. *)
val close : stream -> unit promise
(* TODO Clarify these signatures. *)
val write :
  buffer -> int -> int ->
  (unit -> unit) -> (unit -> unit) -> (exn -> unit) -> stream ->
    unit
val flush : (unit -> unit) -> (unit -> unit) -> (exn -> unit) -> stream -> unit
