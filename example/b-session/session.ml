let () = Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ fun request ->

    match Dream.session_field request "user" with
    | None ->
      Dream.invalidate_session request;
      Dream.set_session_field request "user" "alice";
      Dream.html "You weren't logged in; but now you are!"

    | Some username ->
      Dream.html
        (Printf.sprintf "Welcome back, %s!" (Dream.html_escape username))
