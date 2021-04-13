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
  label : string;
  mutable expires_at : float;
  mutable payload : (string * string) list;
}

type operations = {
  put : string -> string -> unit Lwt.t;
  invalidate : unit -> unit Lwt.t;
  mutable dirty : bool;
}

let session_cookie =
  "dream.session"

let (|>?) =
  Option.bind

(* Session key length is based on

     https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#session-id-length

   ...extended to the next multiple of 6 for a nice base64 encoding.

   NIST recommends 64 bits:

     https://pages.nist.gov/800-63-3/sp800-63b.html#sec7

   ..and links to OWASP.

   Some rough bounds give a maximal probability of 2^-70 for a collision between
   two keys among 100,000,000,000 concurrent sessions (5x the monthly traffic of
   google.com in February 2021). *)
let new_key () =
  Dream__cipher.Random.random 18 |> Dream__pure.Formats.to_base64url

let new_label () =
  Dream__cipher.Random.random 9 |> Dream__pure.Formats.to_base64url

(* TODO Must test session sharing. Should there be at-a-distance
   invalidation? *)
module Memory =
struct
  let rec create hash_table expires_at =
    let key = new_key () in
    if Hashtbl.mem hash_table key then
      create hash_table expires_at
    else begin
      let session = {
        key;
        label = new_label ();
        expires_at;
        payload = [];
      } in
      Hashtbl.replace hash_table key session;
      session
    end

  let put session name value =
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
      put =
        (fun name value -> put !session name value);
      invalidate =
        (fun () -> invalidate hash_table lifetime operations session);
      dirty;
    } in
    operations

  let load hash_table lifetime request =
    let now = Unix.gettimeofday () in

    let valid_session =
      Dream.cookie ~decrypt:false session_cookie request
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
          session_cookie !session.key request response ~encrypt:false ~max_age)

  let back_end lifetime =
    let hash_table = Hashtbl.create 256 in
    {
      load = load hash_table lifetime;
      send;
    }
end

(* TODO This probably needs format prefixes. *)
(* TODO JSON is probably not a good choice for the contents. However, there
   doesn't seem to be a good alternative in opam right now, so using JSON. *)
module Cookie =
struct
  (* Cookie sessions still need keys, even though they are not used as indexes
     (sic!) into a store:

     - For revocation.
     - For binding CSRF tokens to sessions. *)
  let create expires_at = {
    key = new_key ();
    label = new_label ();
    expires_at;
    payload = [];
  }

  let put operations session name value =
    session.payload
    |> List.remove_assoc name
    |> fun dictionary -> (name, value)::dictionary
    |> fun dictionary -> session.payload <- dictionary;
    operations.dirty <- true;
    Lwt.return_unit

  let invalidate lifetime operations session =
    session := create (Unix.gettimeofday () +. lifetime);
    operations.dirty <- true;
    Lwt.return_unit

  let operations lifetime session dirty =
    let rec operations = {
      put = (fun name value -> put operations !session name value);
      invalidate = (fun () -> invalidate lifetime operations session);
      dirty;
    } in
    operations

  let load lifetime request =
    let now = Unix.gettimeofday () in

    let valid_session =
      Dream.cookie session_cookie request
      |>? fun value ->
        (* TODO Is there a non-raising version of this? *)
        match Yojson.Basic.from_string value with
        | `Assoc [
            "key", `String key;
            "label", `String label;
            "expires_at", expires_at;
            "payload", `Assoc payload
          ] ->

          begin match expires_at with
          | `Float n -> Some n
          | `Int n -> Some (Float.of_int n)
          | _ -> None
          end
          |>? fun expires_at ->
            if expires_at <= now then
              None
            else
              let payload =
                (* TODO Don't raise. *)
                payload |> List.map (function
                  | name, `String value -> name, value
                  | _ -> failwith "Bad payload")
              in
              Some {
                key;
                label;
                expires_at;
                payload;
              }

        | _ -> None
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
        true, create (now +. lifetime)
    in

    let session = ref session in
    Lwt.return (operations lifetime session dirty, session)

  let send (operations, session) request response =
    if not operations.dirty then
      Lwt.return response
    else
      let max_age = !session.expires_at -. Unix.gettimeofday () in
      let value =
        `Assoc [
          "key", `String !session.key;
          "label", `String !session.label;
          "expires_at", `Float !session.expires_at;
          "payload", `Assoc (!session.payload |> List.map (fun (name, value) ->
            name, `String value))
        ]
        |> Yojson.Basic.to_string
      in
      Lwt.return
        (Dream.set_cookie session_cookie value request response ~max_age)

  let back_end lifetime = {
    load = load lifetime;
    send;
  }
end

let {middleware; getter} =
  typed_middleware ()
    ~show_value:(fun (_, session) ->
      !session.payload
      |> List.map (fun (name, value) -> Printf.sprintf "%S: %S" name value)
      |> String.concat ", "
      |> Printf.sprintf "%s [%s]" !session.label)

let two_weeks =
  60. *. 60. *. 24. *. 7. *. 2.

let memory_sessions ?(lifetime = two_weeks) =
  middleware (Memory.back_end lifetime)

let cookie_sessions ?(lifetime = two_weeks) =
  middleware (Cookie.back_end lifetime)

let session name request =
  List.assoc_opt name (!(snd (getter request)).payload)

let put_session name value request =
  (fst (getter request)).put name value

let all_session_values request =
  !(snd (getter request)).payload

let invalidate_session request =
  (fst (getter request)).invalidate ()

let session_key request =
  !(snd (getter request)).key

let session_label request =
  !(snd (getter request)).label

let session_expires_at request =
  !(snd (getter request)).expires_at
