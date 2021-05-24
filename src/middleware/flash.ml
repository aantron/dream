(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)


module Dream = Dream__pure.Inmost



let log =
  Log.sub_log "dream.flash"

type 'a back_end = {
  load : Dream.request -> 'a Lwt.t;
  send : 'a -> Dream.request -> Dream.response -> Dream.response Lwt.t;
}

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
  id : string;
  label : string;
  mutable expires_at : float;
  mutable payload : string list;
}

type operations = {
  put : string -> unit Lwt.t;
  invalidate : unit -> unit Lwt.t;
  mutable dirty : bool;
}

let session_cookie =
  "dream.session"

let (|>?) =
  Option.bind

(* Session id length is based on

     https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#session-id-length

   ...extended to the next multiple of 6 for a nice base64 encoding.

   NIST recommends 64 bits:

     https://pages.nist.gov/800-63-3/sp800-63b.html#sec7

   ..and links to OWASP.

   Some rough bounds give a maximal probability of 2^-70 for a collision between
   two IDs among 100,000,000,000 concurrent sessions (5x the monthly traffic of
   google.com in February 2021). *)
let new_id () =
  Dream__cipher.Random.random 18 |> Dream__pure.Formats.to_base64url

let new_label () =
  Dream__cipher.Random.random 9 |> Dream__pure.Formats.to_base64url

let version_session_id id =
  "0" ^ id

let read_session_id id =
  if String.length id < 1 then None
  else
    if id.[0] <> '0' then None
    else Some (String.sub id 1 (String.length id - 1))

let version_value =
  version_session_id

let read_value =
  read_session_id

module Memory =
struct
  let rec create hash_table expires_at =
    let id = new_id () in
    if Hashtbl.mem hash_table id then
      create hash_table expires_at
    else begin
      let session = {
        id;
        label = new_label ();
        expires_at;
        payload = [];
      } in
      Hashtbl.replace hash_table id session;
      session
    end

  let put session message =
    session.payload
    |> fun dictionary -> message::dictionary
    |> fun dictionary -> session.payload <- dictionary;
    Lwt.return_unit

  let invalidate hash_table lifetime operations session =
    Hashtbl.remove hash_table !session.id;
    session := create hash_table (Unix.gettimeofday () +. lifetime);
    operations.dirty <- true;
    Lwt.return_unit

  let operations hash_table lifetime session dirty =
    let rec operations = {
      put =
        (fun message -> put !session message);
      invalidate =
        (fun () -> invalidate hash_table lifetime operations session);
      dirty;
    } in
    operations

  let load hash_table lifetime request =
    let now = Unix.gettimeofday () in

    let valid_session =
      Dream.cookie ~decrypt:false session_cookie request
      |>? read_session_id
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
      let id = version_session_id !session.id in
      let max_age = !session.expires_at -. Unix.gettimeofday () in
      Lwt.return
        (Dream.set_cookie
          session_cookie id request response ~encrypt:false ~max_age)

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
      |> List.map (fun message -> Printf.sprintf "%S" message)
      |> String.concat ", "
      |> Printf.sprintf "%s [%s]" !session.label)

let two_weeks =
  60. *. 60. *. 24. *. 7. *. 2.

let flash_messages ?(lifetime = two_weeks) =
  middleware (Memory.back_end lifetime)

let add_message message request =
  (fst (getter request)).put message

let get_messages request =
  !(snd (getter request)).payload

let clear_messages request =
  (fst (getter request)).invalidate ()

(*
let session_id request =
  !(snd (getter request)).id

let session_label request =
  !(snd (getter request)).label

let session_expires_at request =
  !(snd (getter request)).expires_at
*)
