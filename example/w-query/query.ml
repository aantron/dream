let () =
  Dream.run (fun request ->
    match Dream.query "echo" request with
    | None ->
      Dream.html "Use ?echo=foo to give a message to echo!"
    | Some message ->
      Dream.html (Dream.html_escape message))
