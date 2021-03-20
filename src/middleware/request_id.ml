(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO The other major built-in middleware, prefix, is actually just going to
   be built-in code. So it's probably best to look into building in request_id,
   and getting rid of the concept of built-in middleware. *)

module Dream = Dream__pure.Inmost



let name =
  "dream.request_id"

let last_id =
  Dream.new_global
    (fun () -> ref 0)
    ~debug:(fun id -> "dream.request_id.last_id", string_of_int !id)

let id =
  Dream.new_local
    ()
    ~debug:(fun id -> name, id)

let lwt_key =
  Lwt.new_key ()



(* TODO Request id *getter* should be called request_id, not the middleware. *)
(* TODO Now that the request id is built in, there is no good way for the user
   to pass in a prefix... except perhaps through the app. However, this is
   probably worth it, because adding request_id to every single middleware
   stack is extremely annoying, given that you always want it and it's so cheap
   that there is no reason not to use it. It's probably very rare that someone
   needs a prefix. *)
let request_id ?(prefix = "") next_handler request =

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
      Dream.local id request
  in

  (* If no id was found from the maybe-request, look in the promise-chain-local
     storage. *)
  match request_id with
  | Some _ -> request_id
  | None ->
    Lwt.get lwt_key



(* TODO LATER Maybe it's better to build the request id straight into the
   runtime? There's no real cost to it... is there? And when wouldn't the user
   want a request id? *)
(* TODO LATER List arguments for built-in middlewares: 0 or so cost, highly
   beneficial, in some cases (prefix) actually necessary for correct operation
   of a website. *)
