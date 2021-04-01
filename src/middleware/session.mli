(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



type 'a session

val session_key : 'a session -> string
val session_id : 'a session -> string
val session_expires_at : 'a session -> float
val session_data : 'a session -> 'a
val set_session_data : 'a -> 'a session -> unit Lwt.t
val invalidate_session : 'a session -> unit Lwt.t

type 'a session_info
type 'a store

(* TODO It would also be nice if it was possible to pass extra arguments to the
   middleware thing or the store...? Since the store is responsible for the
   cookies, it's enough to be able to configure the store. *)
type 'a typed = {
  sessions : 'a store -> Dream.middleware;
  session : Dream.request -> 'a session;
}

val typed : 'a session Dream.local -> 'a typed
(* TODO Can we just generate the locals internally? It's probably better to let
   the uesr provide them at least optionally, so that they can set debug
   info. *)

type request = Dream.request
type response = Dream.response

(* TODO Likely need a different set of primitives to support atomic
   operations. *)
val store :
  load:(request -> 'a session_info option Lwt.t) ->
  create:
    ('a session_info option -> request -> float -> 'a session_info Lwt.t) ->
  set:('a session_info -> request -> unit Lwt.t) ->
  send:('a session_info -> request -> response -> response Lwt.t) ->
    'a store

(* TODO The default value is really the weakness of this scheme, as compared
   with a lazy session. However, a lazy session is more annoying, again, for
   CSRF, etc. *)
val memory_sessions : 'a -> 'a store



module Exported_defaults :
sig
   val memory_sessions : Dream.middleware

   val session : string -> Dream.request -> string option
   val all_session_values : Dream.request -> (string * string) list
   val set_session : string -> string -> Dream.request -> unit Lwt.t

   val invalidate_session : Dream.request -> unit Lwt.t

   val session_key : Dream.request -> string
   val session_id : Dream.request -> string
   val session_expires_at : Dream.request -> float
end
