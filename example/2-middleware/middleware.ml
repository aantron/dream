let () =
  Dream.run
  @@ Dream.logger
  @@ fun _ -> Dream.html "Good morning, world!"
