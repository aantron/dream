let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ fun _ -> Dream.html "Good morning, world!"
