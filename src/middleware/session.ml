(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* https://ulrikstrid.github.io/ocaml-cookie/cookie/Cookie/index.html
   https://ulrikstrid.github.io/ocaml-cookie/session-cookie-lwt/Session_cookie_lwt/Make/index.html
   https://github.com/inhabitedtype/ocaml-session#readme *)

(* TODO LATER Achieve database sessions. *)

(* TODO Does HTTP/2, for example, allow connection-based session validation, as
   an optimization? Is that secure? *)

(* https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html *)

module Dream = Dream__pure.Inmost



type request = Dream.request
type response = Dream.response

(* TODO Probably also needs a dirty bit...? Data should be mutable? *)
(* TODO There is sense in only updating the expiration time, as that can be
   cheaper than serializing the data. *)
type 'a session_info = {
  key : string;
  id : string;
  expires_at : int64;
  data : 'a;
}

type 'a session = {
  mutable session_info : 'a session_info;
  store : 'a store;
  request : request;
  use_expires_in : int64;
}

and 'a store = {
  load : request -> 'a session_info option Lwt.t;
  create : 'a session_info option -> request -> int64 -> 'a session_info Lwt.t;
  set : 'a session_info -> request -> unit Lwt.t;
  send : 'a session_info -> request -> response -> response Lwt.t;
}

let session_key session =
  session.session_info.key

let session_id session =
  session.session_info.id

let session_expires_at session =
  session.session_info.expires_at

let session_data session =
  session.session_info.data

let set_session_data data session =
  session.session_info <- {session.session_info with data = data};
  session.store.set session.session_info session.request

let invalidate_session session =
  let expires_at =
    Int64.add (Unix.gettimeofday () |> Int64.of_float) session.use_expires_in in
  let%lwt session_info =
    session.store.create (Some session.session_info) session.request expires_at
  in
  session.session_info <- session_info;
  Lwt.return_unit

let store ~load ~create ~set ~send = {
  load;
  create;
  set;
  send;
}

(* Used for the default sub-log name, cookie name, and request variable name. *)
let module_name =
  "dream.session"

(* TODO Actually use the log somewhere...... *)
let log =
  Log.sub_log module_name

(* TODO Make session expiration configurable somewhere. *)
let valid_for =
  Int64.of_int (60 * 60 * 24 * 7 * 2)

(* TODO LATER Need a session garbage collector, probably. *)
(* TODO LATER Can avoid renewing sessions too often by renewing only when they
   are at least half-expired. *)
let sessions request_local_variable store = fun next_handler request ->

  let now = Unix.gettimeofday () |> Int64.of_float in

  (* Try to load a session, given the cookies and/or headers in the request. *)
  let%lwt maybe_session_info = store.load request in

  (* If no session is found, create one. Otherwise, if a session is found,
     check its expiration time. If too old, re-create a session. The old session
     is passed to the store so as to copy over any settings that may be
     relevant. The store can simply ignore it. *)
  let%lwt session_info =
    match maybe_session_info with
    | None ->
      let%lwt session_info =
        store.create None request (Int64.add now valid_for) in
      log.info (fun log -> log "Session %s created" session_info.id);
      Lwt.return session_info

    | Some session_info ->
      if now < Int64.add session_info.expires_at valid_for then
        let expires_at = Int64.add now valid_for in
        Lwt.return {session_info with expires_at}
      else begin
        let%lwt new_session_info =
          store.create maybe_session_info request (Int64.add now valid_for) in
        log.info (fun log -> log "Session %s expired; creatd %s"
          session_info.id new_session_info.id);
        Lwt.return new_session_info
      end
  in

  let session = {
    session_info;
    store;
    request;
    use_expires_in = valid_for;
  } in

  (* TODO Consider also storing the session id in an Lwt key for the logger to
     use. *)
  let request = Dream.with_local request_local_variable session request in

  let%lwt response = next_handler request in

  (* Set cookies, or whateer needs to be done. *)
  store.send session.session_info request response

let session request_local_variable request =
  match Dream.local request_local_variable request with
  | Some session -> session
  | None ->
    let message = "Dream.session: missing session middleware" in
    log.error (fun log -> log ~request "%s" message);
    failwith message
(* TODO Print the request-local variable name *)

type 'a typed = {
  sessions : 'a store -> Dream.middleware;
  session : Dream.request -> 'a session;
}

let typed request_local_variable = {
  sessions = sessions request_local_variable;
  session = session request_local_variable;
}



let in_memory_sessions default_value =
  let hash_table = Hashtbl.create 256 in

  let load request =
    match Dream.cookie ~decrypt:false module_name request with
    | None -> Lwt.return_none
    | Some potential_session_key ->
      Lwt.return (Hashtbl.find_opt hash_table potential_session_key)
  in

  (* TODO Consider UUIDs for session keys rather than just bare random strings.
     Even though a collision is so unlikely... *)
  let create _ _ expires_at =
    let key =
      Dream__pure.Random.random 38 |> Dream__pure.Formats.to_base64url in
    let id = String.sub key 0 8 in
    let session_info = {
      key;
      id;
      expires_at;
      data = default_value;
    } in
    Hashtbl.replace hash_table key session_info;
    Lwt.return session_info
  in

  let set session_info _ =
    Hashtbl.replace hash_table session_info.key session_info;
    Lwt.return_unit
  in

  (* TODO Cookie scope and security! Use the site prefix from the request. *)
  let send session_info request response =
    response
    |> Dream.add_set_cookie
      module_name session_info.key request ~secure:false ~encrypt:false
    |> Lwt.return
  in

  store ~load ~create ~set ~send



module Exported_defaults =
struct
  (* TODO Debug info. *)
  let dictionary_sessions_variable =
    Dream.new_local ()

  let dictionary_sessions =
    typed dictionary_sessions_variable

  let sessions_in_memory =
    dictionary_sessions.sessions (in_memory_sessions [])

  let session_key request =
    session_key (dictionary_sessions.session request)

  let session_id request =
    session_id (dictionary_sessions.session request)

  let session_expires_at request =
    session_expires_at (dictionary_sessions.session request)

  let session key request =
    request
    |> dictionary_sessions.session
    |> session_data
    |> List.assoc_opt key

  let all_session_values request =
    request
    |> dictionary_sessions.session
    |> session_data

  let set_session key value request =
    let session = dictionary_sessions.session request in
    session
    |> session_data
    |> List.remove_assoc key
    |> fun dictionary -> (key, value)::dictionary
    |> fun dictionary -> set_session_data dictionary session

  let invalidate_session request =
    invalidate_session (dictionary_sessions.session request)
end

(* TODO Currently using some sloppy format to flatten string * string lists into
   cookie-safe strings. It's neither space- nor time-efficient. *)
let _dictionary_to_string dictionary =
  let buffer = Buffer.create 4096 in

  dictionary |> List.iter (fun (key, value) ->
    let key = Dream__pure.Formats.to_base64url key in
    let value = Dream__pure.Formats.to_base64url value in

    Printf.bprintf buffer "%i_%s%i_%s"
      (String.length key) key (String.length value) value);

  Buffer.contents buffer

let _string_to_dictionary string =
  let load_string index =
    match String.index_from_opt string index '_' with
    | None -> None
    | Some underscore_index ->
      let length_string = String.sub string index (underscore_index - index) in
      match int_of_string length_string with
      | exception _ -> None
      | length ->
        match String.sub string (underscore_index + 1) length with
        | exception _ -> None
        | value ->
          match Dream__pure.Formats.from_base64url value with
          | Error _ -> None
          | Ok value -> Some (value, index + underscore_index + 1 + length)
  in

  let load_pair index =
    match load_string index with
    | None -> None
    | Some (key, index) ->
      match load_string index with
      | None -> None
      | Some (value, index) ->
        Some ((key, value), index)
  in

  let rec load_dictionary index accumulator =
    match load_pair index with
    | None -> accumulator
    | Some (pair, index) -> load_dictionary index (pair::accumulator)
  in

  load_dictionary 0
