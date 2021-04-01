(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let log =
  Dream__middleware.Log.sub_log "dream.sql"

let pool : (_, Caqti_error.connect) Caqti_lwt.Pool.t option ref Dream.global =
  Dream.new_global (fun () -> ref None)

(* TODO Set PRAGMA foreign_keys on SQLite3 connections. *)
let sql_pool ?size uri inner_handler request =
  let pool_cell = Dream.global pool request in
  begin match !pool_cell with
  | Some _ -> inner_handler request
  | None ->
    match Caqti_lwt.connect_pool ?max_size:size (Uri.of_string uri) with
    | Ok pool ->
      pool_cell := Some pool;
      inner_handler request
    | Error error ->
      (* Deliberately raise an exception so that it can be communicated to any
         debug handler. *)
      let message =
        Printf.sprintf "Dream.sql_pool: cannot create pool for '%s': %s"
         uri (Caqti_error.show error) in
      log.error (fun log -> log ~request "%s" message);
      failwith message
  end

let sql callback request =
  match !(Dream.global pool request) with
  | None ->
    let message = "Dream.sql: no pool; did you apply Dream.sql_pool?" in
    log.error (fun log -> log ~request "%s" message);
    failwith message
  | Some pool ->
    let%lwt result =
      Caqti_lwt.Pool.use (fun db ->
        let%lwt result = callback db in
        Lwt.return (Ok result))
        pool
    in
    Caqti_lwt.or_fail result
