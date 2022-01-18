(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html *)

module Message = Dream_pure.Message



let log =
  Log.sub_log "dream.session"

type 'a back_end = {
  load : Message.request -> 'a Lwt.t;
  send : 'a -> Message.request -> Message.response -> Message.response Lwt.t;
}

let middleware field back_end = fun inner_handler request ->
  let session = Lwt_eio.Promise.await_lwt (back_end.load request) in
  Message.set_field request field session;
  let response = inner_handler request in
  Lwt_eio.Promise.await_lwt (back_end.send session request response)

let getter field request =
  match Message.field request field with
  | Some session ->
    session
  | None ->
    let message = "Missing session middleware" in
    log.error (fun log -> log ~request "%s" message);
    failwith message

type 'a typed_middleware = {
  middleware : 'a back_end -> Message.middleware;
  getter : Message.request -> 'a;
}

let typed_middleware ?show_value () =
  let field = Message.new_field ~name:"dream.session" ?show_value () in
  {
    middleware = middleware field;
    getter = getter field;
  }



type session = {
  id : string;
  label : string;
  mutable expires_at : float;
  mutable payload : (string * string) list;
}

type operations = {
  put : string -> string -> unit;
  invalidate : unit -> unit;
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
  Dream__cipher.Random.random 18 |> Dream_pure.Formats.to_base64url

let new_label () =
  Dream__cipher.Random.random 9 |> Dream_pure.Formats.to_base64url

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

  let put session name value =
    session.payload
    |> List.remove_assoc name
    |> fun dictionary -> (name, value)::dictionary
    |> fun dictionary -> session.payload <- dictionary

  let invalidate hash_table ~now lifetime operations session =
    Hashtbl.remove hash_table !session.id;
    session := create hash_table (now () +. lifetime);
    operations.dirty <- true

  let operations ~now hash_table lifetime session dirty =
    let rec operations = {
      put =
        (fun name value -> put !session name value);
      invalidate =
        (fun () -> invalidate ~now hash_table lifetime operations session);
      dirty;
    } in
    operations

  let load ~now:gettimeofday hash_table lifetime request =
    let now = gettimeofday () in

    let valid_session =
      Cookie.cookie ~decrypt:false request session_cookie
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
    Lwt.return (operations ~now:gettimeofday hash_table lifetime session dirty, session)

  let send ~now (operations, session) request response =
    if operations.dirty then begin
      let id = version_session_id !session.id in
      let max_age = !session.expires_at -. now () in
      Cookie.set_cookie
        response session_cookie id request ~encrypt:false ~max_age
    end;
    Lwt.return response

  let back_end ~now lifetime =
    let hash_table = Hashtbl.create 256 in
    {
      load = load ~now hash_table lifetime;
      send = send ~now;
    }
end

(* TODO JSON is probably not a good choice for the contents. However, there
   doesn't seem to be a good alternative in opam right now, so using JSON. *)
module Cookie =
struct
  (* Cookie sessions still need keys, even though they are not used as indexes
     (sic!) into a store:

     - For revocation.
     - For binding CSRF tokens to sessions. *)
  let create expires_at = {
    id = new_id ();
    label = new_label ();
    expires_at;
    payload = [];
  }

  let put operations session name value =
    session.payload
    |> List.remove_assoc name
    |> fun dictionary -> (name, value)::dictionary
    |> fun dictionary -> session.payload <- dictionary;
    operations.dirty <- true

  let invalidate ~now lifetime operations session =
    session := create (now () +. lifetime);
    operations.dirty <- true

  let operations ~now lifetime session dirty =
    let rec operations = {
      put = (fun name value -> put operations !session name value);
      invalidate = (fun () -> invalidate ~now lifetime operations session);
      dirty;
    } in
    operations

  let load ~now:gettimeofday lifetime request =
    let now = gettimeofday () in

    let valid_session =
      Cookie.cookie request session_cookie
      |>? read_value
      |>? fun value ->
        (* TODO Is there a non-raising version of this? *)
        match Yojson.Basic.from_string value with
        | `Assoc [
            "id", `String id;
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
                id;
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
    Lwt.return (operations ~now:gettimeofday lifetime session dirty, session)

  let send ~now (operations, session) request response =
    if operations.dirty then begin
      let max_age = !session.expires_at -. now () in
      let value =
        `Assoc [
          "id", `String !session.id;
          "label", `String !session.label;
          "expires_at", `Float !session.expires_at;
          "payload", `Assoc (!session.payload |> List.map (fun (name, value) ->
            name, `String value))
        ]
        |> Yojson.Basic.to_string
        |> version_value
      in
      Cookie.set_cookie response session_cookie value request ~max_age
    end;
    Lwt.return response

  let back_end ~now lifetime = {
    load = load ~now lifetime;
    send = send ~now;
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

module Make (Pclock : Mirage_clock.PCLOCK) = struct
  let now () = Ptime.to_float_s (Ptime.v (Pclock.now_d_ps ()))

  let memory_sessions ?(lifetime = two_weeks) =
    middleware (Memory.back_end ~now lifetime)

  let cookie_sessions ?(lifetime = two_weeks) =
    middleware (Cookie.back_end ~now lifetime)
end

let session name request =
  List.assoc_opt name (!(snd (getter request)).payload)

let put_session name value request =
  (fst (getter request)).put name value

let all_session_values request =
  !(snd (getter request)).payload

let invalidate_session request =
  (fst (getter request)).invalidate ()

let session_id request =
  !(snd (getter request)).id

let session_label request =
  !(snd (getter request)).label

let session_expires_at request =
  !(snd (getter request)).expires_at
