let () =
  Dream.run
  @@ Dream.logger
  @@ fun _ -> Dream.respond "Good morning, world!"
