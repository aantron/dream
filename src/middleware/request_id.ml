module Dream = Dream_pure.Inmost



let last_id =
  Dream.new_global ~initializer_:(fun () ->
    ref 0)

let id =
  Dream.new_local ()

let lwt_key =
  Lwt.new_key ()



let assign ?(prefix = "") next_handler request =

  (* Get the last id for this request's app, increment it, and prepend the
     prefix. *)
  let last_id_ref : int ref =
    Dream.global last_id request in

  incr last_id_ref;

  let new_id =
    prefix ^ (string_of_int !last_id_ref) in

  (* Store the new id in the request and in the Lwt promise values map for
     best-effort delivery to all code that might want the id. Continue into the
     rest of the app. *)
  let request =
    Dream.with_local id new_id request in

  Lwt.with_value
    lwt_key
    (Some new_id)
    (fun () ->
      next_handler request)



let get_option ?request () =

  (* First, try to get the id from the request, if one was provided. *)
  let request_id =
    match request with
    | None -> None
    | Some request ->
      Dream.local_option id request
  in

  (* If no id was found from the maybe-request, look in the promise-chain-local
     storage. *)
  match request_id with
  | Some _ -> request_id
  | None ->
    Lwt.get lwt_key
