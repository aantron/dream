let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sessions_in_memory
  @@ fun request ->
    match Dream.session "user" request with
    | None ->
      let%lwt () = Dream.invalidate_session request in
      let%lwt () = Dream.set_session "user" "anastasios" request in
      Dream.respond "You weren't logged in; but now you are!"

    | Some username ->
      Printf.ksprintf
        Dream.respond "Welcome back, %s!" (Dream.html_escape username)
