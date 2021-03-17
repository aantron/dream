open Lwt.Infix

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sessions_in_memory
  @@ (fun request ->

    match Dream.session "user" request with
    | None ->
      Dream.set_session "user" "anastasios" request >>= fun () ->
      Dream.respond "You weren't logged in; but now you are!"

    | Some username ->
      Printf.ksprintf
        Dream.respond "Welcome back, %s!" username)

(* TODO "Protect" against session fixation and XSS, or at least mention these in
   the README. *)
