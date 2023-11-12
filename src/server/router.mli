(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Message = Dream_pure.Message

type route

(* Leaf routes. *)
val get : string -> Message.handler -> route
val post : string -> Message.handler -> route
val put : string -> Message.handler -> route
val delete : string -> Message.handler -> route
val head : string -> Message.handler -> route
val connect : string -> Message.handler -> route
val options : string -> Message.handler -> route
val trace : string -> Message.handler -> route
val patch : string -> Message.handler -> route
val any : string -> Message.handler -> route
val no_route : route

(* Route groups. *)
val scope : string -> Message.middleware list -> route list -> route

(* The middleware and the path parameter retriever. With respect to path
   parameters, the middleware is the setter, and the retriever is, of course,
   the getter. *)
val router : route list -> Message.handler
val param : Message.request -> string -> string

(* Variables used by the router. *)
val path : Message.request -> string list
val prefix : Message.request -> string
val set_path : Message.request -> string list -> unit
val set_prefix : Message.request -> string list -> unit

(**/**)

type token =
  | Literal of string
  | Param of string
  | Wildcard of string

val parse : string -> token list
