let () =
  Dream.run (fun request ->
    match Dream.query "echo" request with
    | None ->
      Dream.respond "Use ?echo=foo to give a message to echo!"
    | Some message ->
      Dream.respond (Dream.html_escape message))
