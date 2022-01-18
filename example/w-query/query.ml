let () =
  Eio_main.run @@ fun env ->
  Dream.run env (fun request ->
    match Dream.query "echo" request with
    | None ->
      Dream.html "Use ?echo=foo to give a message to echo!"
    | Some message ->
      Dream.html (Dream.html_escape message))
