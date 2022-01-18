let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ fun request ->

    match Dream.session "user" request with
    | None ->
      Dream.invalidate_session request;
      Dream.put_session "user" "alice" request;
      Dream.html "You weren't logged in; but now you are!"

    | Some username ->
      Printf.ksprintf
        Dream.html "Welcome back, %s!" (Dream.html_escape username)
