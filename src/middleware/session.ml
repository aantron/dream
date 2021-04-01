(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO LATER Achieve database sessions. *)

(* TODO Does HTTP/2, for example, allow connection-based session validation, as
   an optimization? Is that secure? *)

(* https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html *)

module Dream = Dream__pure.Inmost



(* Used for the default sub-log name, cookie name, and request variable name. *)
(* let module_name =
  "dream.session" *)

(* TODO Actually use the log somewhere...... *)
let log =
  Log.sub_log "dream.session"

(* TODO Make session expiration configurable somewhere. *)
(* let valid_for =
  60. *. 60. *. 24. *. 7. *. 2. *)

type 'a back_end = {
  load : Dream.request -> 'a Lwt.t;
  send : 'a -> Dream.request -> Dream.response -> Dream.response Lwt.t;
}

(* TODO LATER Need a session garbage collector, probably. *)
(* TODO LATER Can avoid renewing sessions too often by renewing only when they
   are at least half-expired. *)
(* TODO To support atomic operations, the loader HAS to be able to load, expire,
   create, and renew the session. *)
let middleware local back_end = fun inner_handler request ->

  let%lwt session =
    back_end.load request in
  let request =
    Dream.with_local local session request in

  let%lwt response =
    inner_handler request in

  back_end.send session request response

let getter local request =
  match Dream.local local request with
  | Some session ->
    session
  | None ->
    let message = "Missing session middleware" in
    log.error (fun log -> log ~request "%s" message);
    failwith message
(* TODO Print the request-local variable name *)

type 'a typed_middleware = {
  middleware : 'a back_end -> Dream.middleware;
  getter : Dream.request -> 'a;
}

let typed_middleware ?show_value () =
  let local = Dream.new_local ~name:"dream.session" ?show_value () in
  {
    middleware = middleware local;
    getter = getter local;
  }



type session = {
  key : string;
  id : string;
  mutable expires_at : float;
  mutable payload : (string * string) list;
}

type operations = {
  set : string -> string -> unit Lwt.t;
  invalidate : unit -> unit Lwt.t;
  mutable dirty : bool;
}

let cookie =
  "dream.session"

let (|>?) =
  Option.bind

module Memory =
struct
  let rec create hash_table expires_at =
    let key =
      Dream__pure.Random.random 33 |> Dream__pure.Formats.to_base64url in
    if Hashtbl.mem hash_table key then
      create hash_table expires_at
    else begin
      let session = {
        key;
        id = Dream__pure.Random.random 9 |> Dream__pure.Formats.to_base64url;
        expires_at;
        payload = [];
      } in
      Hashtbl.replace hash_table key session;
      session
    end

  let set session name value =
    session.payload
    |> List.remove_assoc name
    |> fun dictionary -> (name, value)::dictionary
    |> fun dictionary -> session.payload <- dictionary;
    Lwt.return_unit

  let invalidate hash_table lifetime operations session =
    Hashtbl.remove hash_table !session.key;
    session := create hash_table (Unix.gettimeofday () +. lifetime);
    operations.dirty <- true;
    Lwt.return_unit

  let operations hash_table lifetime session dirty =
    let rec operations = {
      set =
        (fun name value -> set !session name value);
      invalidate =
        (fun () -> invalidate hash_table lifetime operations session);
      dirty;
    } in
    operations

  let load hash_table lifetime request =
    let now = Unix.gettimeofday () in

    let valid_session =
      Dream.cookie ~decrypt:false "dream.session" request
      |>? Hashtbl.find_opt hash_table
      |>? fun session ->
        if session.expires_at > now then
          Some session
        else begin
          Hashtbl.remove hash_table session.key;
          None
        end
    in

    let dirty, session =
      match valid_session with
      | Some session ->
        if session.expires_at -. now > (lifetime /. 2.) then
          false, session
        else begin
          session.expires_at <- now +. lifetime;
          true, session
        end
      | None ->
        true, create hash_table (now +. lifetime)
    in

    let session = ref session in
    Lwt.return (operations hash_table lifetime session dirty, session)

  let send (operations, session) request response =
    if not operations.dirty then
      Lwt.return response
    else
      let max_age = !session.expires_at -. Unix.gettimeofday () in
      Lwt.return
        (Dream.set_cookie
          cookie !session.key request response ~encrypt:false ~max_age)

  let back_end lifetime =
    let hash_table = Hashtbl.create 256 in
    {
      load = load hash_table lifetime;
      send;
    }
end

let {middleware; getter} =
  typed_middleware ()
    ~show_value:(fun (_, session) ->
      !session.payload
      |> List.map (fun (name, value) -> Printf.sprintf "%S: %S" name value)
      |> String.concat ", "
      |> Printf.sprintf "%s [%s]" !session.id)

let two_weeks =
  60. *. 60. *. 24. *. 7. *. 2.

let memory_sessions ?(lifetime = two_weeks) =
  middleware (Memory.back_end lifetime)

let session name request =
  List.assoc_opt name (!(snd (getter request)).payload)

let set_session name value request =
  (fst (getter request)).set name value

let all_session_values request =
  !(snd (getter request)).payload

let invalidate_session request =
  (fst (getter request)).invalidate ()

let session_key request =
  !(snd (getter request)).key

let session_id request =
  !(snd (getter request)).id

let session_expires_at request =
  !(snd (getter request)).expires_at

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
