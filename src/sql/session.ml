(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure
module Cookie = Dream__server.Cookie
module Session = Dream__server.Session



let (|>?) =
  Option.bind

module type DB = Caqti_lwt.CONNECTION

module R = Caqti_request
module T = Caqti_type

let serialize_payload payload =
  payload
  |> List.map (fun (name, value) -> name, `String value)
  |> fun assoc -> `Assoc assoc
  |> Yojson.Basic.to_string

let insert =
  let query =
    R.exec T.(tup4 string string float string) {|
      INSERT INTO dream_session (id, label, expires_at, payload)
      VALUES ($1, $2, $3, $4)
    |} in

  fun (module Db : DB) (session : Session.session) ->
    let payload = serialize_payload session.payload in
    let%lwt result =
      Db.exec query (session.id, session.label, session.expires_at, payload) in
    Caqti_lwt.or_fail result

let find_opt =
  let query =
    R.find_opt T.string T.(tup3 string float string)
      "SELECT label, expires_at, payload FROM dream_session WHERE id = $1" in

  fun (module Db : DB) id ->
    let%lwt result = Db.find_opt query id in
    match%lwt Caqti_lwt.or_fail result with
    | None -> Lwt.return_none
    | Some (label, expires_at, payload) ->
      (* TODO Mind exceptions! *)
      let payload =
        Yojson.Basic.from_string payload
        |> function
          | `Assoc payload ->
            payload |> List.map (function
              | name, `String value -> name, value
              | _ -> failwith "Bad payload")
          | _ -> failwith "Bad payload"
      in
      Lwt.return_some Session.{
        id;
        label;
        expires_at;
        payload;
      }

let refresh =
  let query =
    R.exec T.(tup2 float string)
      "UPDATE dream_session SET expires_at = $1 WHERE id = $2" in

  fun (module Db : DB) (session : Session.session) ->
    let%lwt result = Db.exec query (session.expires_at, session.id) in
    Caqti_lwt.or_fail result

let update =
  let query =
    R.exec T.(tup2 string string)
      "UPDATE dream_session SET payload = $1 WHERE id = $2" in

  fun (module Db : DB) (session : Session.session) ->
    let payload = serialize_payload session.payload in
    let%lwt result = Db.exec query (payload, session.id) in
    Caqti_lwt.or_fail result

let remove =
  let query = R.exec T.string "DELETE FROM dream_session WHERE id = $1" in

  fun (module Db : DB) id ->
    let%lwt result = Db.exec query id in
    Caqti_lwt.or_fail result

(* TODO Session sharing is greatly complicated by the backing store; is it ok to
   just work with snapshots? All kinds of race conditions may be possible,
   unless there is a generation value or the like. *)
(* TODO This can be greatly addressed with a cache, which is desirable
   anyway. *)
(* TODO The in-memory sessions manager should actually be re-done in terms of
   the cache, just with no persistent backing store. *)

let rec create db expires_at attempt =
  let session = Session.{
    id = Session.new_id ();
    label = Session.new_label ();
    expires_at;
    payload = [];
  } in
  (* Assume that any exception is a PRIMARY KEY collision (extremely unlikely)
     and try a couple more times. *)
  match%lwt insert db session with
  | exception Caqti_error.Exn _ when attempt <= 3 ->
    create db expires_at (attempt + 1)
  | () ->
    Lwt.return session

let put request (session : Session.session) name value =
  session.payload
  |> List.remove_assoc name
  |> fun dictionary -> (name, value)::dictionary
  |> fun dictionary -> session.payload <- dictionary;
  Lwt_eio.Promise.await_lwt begin
    Sql.sql request (fun db -> update db session)
  end

let invalidate request lifetime operations (session : Session.session ref) =
  Lwt_eio.Promise.await_lwt begin
    Sql.sql request begin fun db ->
      let%lwt () = remove db !session.id in
      let%lwt new_session = create db (Unix.gettimeofday () +. lifetime) 1 in
      session := new_session;
      operations.Session.dirty <- true;
      Lwt.return_unit
    end
  end

let operations request lifetime (session : Session.session ref) dirty =
  let rec operations = {
    Session.put = (fun name value -> put request !session name value);
    invalidate = (fun () -> invalidate request lifetime operations session);
    dirty;
  } in
  operations

let load lifetime request =
  Sql.sql request begin fun db ->
    let now = Unix.gettimeofday () in

    let%lwt valid_session =
      match Cookie.cookie request ~decrypt:false Session.session_cookie with
      | None -> Lwt.return_none
      | Some id ->
        match Session.read_session_id id with
        | None -> Lwt.return_none
        | Some id ->
          match%lwt find_opt db id with
          | None -> Lwt.return_none
          | Some session ->
            if session.expires_at > now then
              Lwt.return (Some session)
            else begin
              let%lwt () = remove db id in
              Lwt.return_none
            end
    in

    let%lwt dirty, session =
      match valid_session with
      | Some session ->
        if session.expires_at -. now > (lifetime /. 2.) then
          Lwt.return (false, session)
        else begin
          session.expires_at <- now +. lifetime;
          let%lwt () = refresh db session in
          Lwt.return (true, session)
        end
      | None ->
        let%lwt session = create db (now +. lifetime) 1 in
        Lwt.return (true, session)
    in

    let session = ref session in
    Lwt.return (operations request lifetime session dirty, session)
  end

let send (operations, session) request response =
  if operations.Session.dirty then begin
    let id = Session.version_session_id !session.Session.id in
    let max_age = !session.Session.expires_at -. Unix.gettimeofday () in
    Cookie.set_cookie
      response
      Session.session_cookie
      id
      request
      ~encrypt:false
      ~max_age
  end;
  Lwt.return response

let back_end lifetime = {
  Session.load = load lifetime;
  send;
}

let sql_sessions ?(lifetime = Session.two_weeks) =
  Session.middleware (back_end lifetime)
