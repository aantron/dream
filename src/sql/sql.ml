(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let log =
  Dream__middleware.Log.sub_log "dream.sql"

(* TODO Debug metadata for the pools. *)
let pool_variable : (_, Caqti_error.t) Caqti_lwt.Pool.t Dream.local =
  Dream.new_local ()

let foreign_keys_on =
  Caqti_request.exec Caqti_type.unit "PRAGMA foreign_keys = ON"

let post_connect (module Db : Caqti_lwt.CONNECTION) =
  match Caqti_driver_info.dialect_tag Db.driver_info with
  | `Sqlite -> Db.exec foreign_keys_on ()
  | _ -> Lwt.return (Ok ())

let sql_pool ?size uri =
    let pool_cell = ref None in
    fun inner_handler request ->

  begin match !pool_cell with
  | Some pool -> inner_handler (Dream.with_local pool_variable pool request)
  | None ->
    let parsed_uri = Uri.of_string uri in
    if Uri.scheme parsed_uri = Some "sqlite" then
      log.warning (fun log -> log ~request
        "Dream.sql_pool: \
        'sqlite' is not a valid scheme; did you mean 'sqlite3'?");
    let pool =
      Caqti_lwt.connect_pool ?max_size:size ~post_connect parsed_uri in
    match pool with
    | Ok pool ->
      pool_cell := Some pool;
      inner_handler (Dream.with_local pool_variable pool request)
    | Error error ->
      (* Deliberately raise an exception so that it can be communicated to any
         debug handler. *)
      let message =
        Printf.sprintf "Dream.sql_pool: cannot create pool for '%s': %s"
         uri (Caqti_error.show error) in
      log.error (fun log -> log ~request "%s" message);
      failwith message
  end

let sql request callback =
  match Dream.local pool_variable request with
  | None ->
    let message = "Dream.sql: no pool; did you apply Dream.sql_pool?" in
    log.error (fun log -> log ~request "%s" message);
    failwith message
  | Some pool ->
    let%lwt result =
      pool |> Caqti_lwt.Pool.use (fun db ->
        (* The special exception handling is a workaround for
           https://github.com/paurkedal/ocaml-caqti/issues/68. *)
        match%lwt callback db with
        | result -> Lwt.return (Ok result)
        | exception exn -> raise exn)
    in
    Caqti_lwt.or_fail result
