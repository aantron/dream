(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Catch = Dream__server.Catch
module Log = Dream__server.Log
module Message = Dream_pure.Message



(* User's error handlers and defaults. These actually generate error response
   templates and/or do logging. *)

val default : Catch.error_handler
val debug_error_handler : Catch.error_handler
val customize :
  (Catch.error -> string -> Message.response -> Message.response Lwt.t) ->
    Catch.error_handler



(* Internal functions called by the framework to report errors. These translate
   various libraries' errors into Error.error and call the user's error
   handler. The signatures are arranged so that these helpers can be partially
   applied and then passed in as arguments where the libraries want error
   handler arguments. *)

(* val app :
  Dream.app ->
  Error.error_handler ->
    Dream.middleware *)

val app :
  Catch.error_handler ->
    (Catch.error -> Message.response Lwt.t)

val httpaf :
  Catch.error_handler ->
    (Unix.sockaddr -> Httpaf.Server_connection.error_handler)

val h2 :
  Catch.error_handler ->
    (Unix.sockaddr -> H2.Server_connection.error_handler)

val tls :
  Catch.error_handler ->
    (Unix.sockaddr -> exn -> unit)

val websocket :
  Catch.error_handler ->
  Message.request ->
  Message.response ->
    (Websocketaf.Wsd.t -> [ `Exn of exn ] -> unit)

val websocket_handshake :
  Catch.error_handler ->
    (Message.request -> Message.response -> string -> Message.response Lwt.t)




(* Logger also used by elsewhere in the HTTP integration. *)
val log : Log.sub_log
