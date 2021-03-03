type request = Opium.Request.t
type response = Opium.Response.t

type handler = request -> response Lwt.t
type middleware = handler -> handler

(* TODO All of them... *)
type method_ = Opium.Method.t

(* https://github.com/rgrinberg/opium/pull/215#issuecomment-727539703 *)

(* TODO The routers are really the main problem. *)
(* type route = method_ * string * handler *)
(* TODO Is fall-through the right choice? *)
(* TODO Actually, if we can query routers... Then it mgiht be possible
   to use some kind of delimiters to associate/scope routes to a follow-on
   router. The alternative is to pass the middleware chain as an argument. *)
val route :
   ?middleware:middleware -> (method_ * string * handler) list -> middleware

(* TODO What is the absolute EASIEST way to understand a router?
   What does the router need to do... It probably needs to be able to
   add middleware to its specific handlers. Definitely. *)

(* TODO Rename?? *)
val param : request -> int -> string

val route_ : method_ -> string -> handler -> method_ * string * handler

module Logger = Logger
module Utf8 = Utf8
