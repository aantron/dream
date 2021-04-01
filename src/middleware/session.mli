(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* Typed session back ends. *)

(* module type Back_end =
sig
   type session

   (* val key : session -> string *)
   (* val id : session -> string *)
   (* val expires_at : session -> float *)

   val load : Dream.request -> session Lwt.t

   (* val create : session option -> Dream.request -> float -> session Lwt.t *)
   (* val set : session -> Dream.request -> unit Lwt.t *)
   val send : session -> Dream.request -> Dream.response -> Dream.response Lwt.t
end

type 'a back_end = (module Back_end with type session = 'a) *)



(* Typed session middleware. *)

(* type 'a back_end = {
  load : Dream.request -> 'a Lwt.t;
  send : 'a -> Dream.request -> Dream.response -> Dream.response Lwt.t;
}

type 'a typed_middleware = {
  middleware : 'a back_end -> Dream.middleware;
  getter : Dream.request -> 'a;
}

val typed_middleware : ?show_value:('a -> string) -> unit -> 'a typed_middleware *)
(* TODO Can we just generate the locals internally? It's probably better to let
   the uesr provide them at least optionally, so that they can set debug
   info. *)



(* Typed session objects. *)

(* type 'a session
type 'a session_info *)
(* TODO Is this nesting of session inside session_info really necessary? *)

(* val session_key : 'a session -> string
val session_id : 'a session -> string
val session_expires_at : 'a session -> float
val session_data : 'a session -> 'a
val set_session_data : 'a -> 'a session -> unit Lwt.t
val invalidate_session : 'a session -> unit Lwt.t *)



(* Storage for typed session objects. *)

(* type 'a back_end *)

(* type request = Dream.request
type response = Dream.response *)

(* TODO Likely need a different set of primitives to support atomic
   operations. *)
(* val back_end :
  load:(request -> 'a option Lwt.t) ->
  create:
    ('a session_info option -> request -> float -> 'a session_info Lwt.t) ->
  set:('a session_info -> request -> unit Lwt.t) ->
  send:('a session_info -> request -> response -> response Lwt.t) ->
    'a back_end *)



(* Specific instances. *)

(* type session *)

(* TODO The default value is really the weakness of this scheme, as compared
   with a lazy session. However, a lazy session is more annoying, again, for
   CSRF, etc. *)
val memory_sessions : ?lifetime:float -> Dream.middleware

(* val cookie_sessions : *)



(* Defaults used in the main interface. *)

(* module Exported_defaults :
sig
   val memory_sessions : Dream.middleware *)

val session : string -> Dream.request -> string option
val set_session : string -> string -> Dream.request -> unit Lwt.t
val all_session_values : Dream.request -> (string * string) list

val invalidate_session : Dream.request -> unit Lwt.t

val session_key : Dream.request -> string
val session_id : Dream.request -> string
val session_expires_at : Dream.request -> float
(* end *)
