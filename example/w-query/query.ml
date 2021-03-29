let () =
  Dream.run (fun request ->
    match Dream.query "echo" request with
    | None -> Dream.respond "Use ?echo=foo to echo a message!"
    | Some message -> Dream.respond (Dream.html_escape message))
