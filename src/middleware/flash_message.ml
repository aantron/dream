(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)


module Dream = Dream__pure.Inmost

(* module Session = Dream__middleware.Session *)

let log =
  Log.sub_log "dream.flash"

type level = Debug | Info | Success | Warning | Error
let level_to_string l = match l with
  | Debug -> "DEBUG"
  | Info -> "INFO"
  | Success -> "SUCCESS"
  | Warning -> "WARNING"
  | Error -> "ERROR"

type flash_message = level * string

type 'a back_end = {
  load : Dream.request -> 'a Lwt.t;
  send : 'a -> Dream.request -> Dream.response -> Dream.response Lwt.t;
}

(** This still doesn't completely capture what the middleware is supposed to do.

    We need to:
    1. Provide any messages that were stored _from the previous request_.
    2. Store any messages that were queued _this request_.
    3. On cleanup, throw away the messages from last time, replace them with those from
       this request.
 *)

let middleware local back_end = fun inner_handler request ->
  let%lwt session = back_end.load request in
  let request = Dream.with_local local session request in
  let%lwt response = inner_handler request in
  back_end.send session request response

let getter local request =
  match Dream.local local request with
  | Some session ->
    session
  | None ->
    let message = "Missing flash message middleware" in
    log.error (fun log -> log ~request "%s" message);
    failwith message

type 'a typed_middleware = {
  middleware : 'a back_end -> Dream.middleware;
  getter : Dream.request -> 'a;
}

let typed_middleware ?show_value () =
  let local = Dream.new_local ~name:"dream.flash_message" ?show_value () in
  {
    middleware = middleware local;
    getter = getter local;
  }

type session = {
  id : string;
  label : string;
  mutable expires_at : float;
  mutable payload : flash_message list;
}

type operations = {
  put : level -> string -> unit Lwt.t;
  invalidate : unit -> unit Lwt.t;
  mutable dirty : bool;
}

let flash_message_cookie =
  "dream.flash_message"

let (|>?) =
  Option.bind


module Memory =
struct
  let rec create hash_table expires_at =
    let id = Session.new_id () in
    if Hashtbl.mem hash_table id then
      create hash_table expires_at
    else begin
      let session = {
        id;
        label = Session.new_label ();
        expires_at;
        payload = [];
      } in
      Hashtbl.replace hash_table id session;
      session
    end

  let put session level message =
    session.payload
    |> fun messages -> (level, message)::messages
    |> fun messages -> session.payload <- messages;
    Lwt.return_unit

  let invalidate hash_table lifetime operations session =
    Hashtbl.remove hash_table !session.id;
    session := create hash_table (Unix.gettimeofday () +. lifetime);
    operations.dirty <- true;
    Lwt.return_unit

  let operations hash_table lifetime session dirty =
    let rec operations = {
      put =
        (fun level message -> put !session level message);
      invalidate =
        (fun () -> invalidate hash_table lifetime operations session);
      dirty;
    } in
    operations

  let load hash_table lifetime request =
    let now = Unix.gettimeofday () in

    let valid_session =
      Dream.cookie ~decrypt:false flash_message_cookie request
      |>? Session.read_session_id
      |>? Hashtbl.find_opt hash_table
      |>? fun session ->
        if session.expires_at > now then
          Some session
        else begin
          Hashtbl.remove hash_table session.id;
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
      let id = Session.version_session_id !session.id in
      let max_age = !session.expires_at -. Unix.gettimeofday () in
      Lwt.return
        (Dream.set_cookie
          flash_message_cookie id request response ~encrypt:false ~max_age)

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
      |> List.map (fun (l, m) -> Printf.sprintf "%S : %S" (level_to_string l) m)
      |> String.concat ", "
      |> Printf.sprintf "%s [%s]" !session.label)

let one_hour = 60. *. 60.

let flash_messages ?(lifetime = one_hour) =
  middleware (Memory.back_end lifetime)

let add_message level message request =
  (fst (getter request)).put level message

let get_messages request =
  !(snd (getter request)).payload

let clear_messages request =
  (fst (getter request)).invalidate ()
