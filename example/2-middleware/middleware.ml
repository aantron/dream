let () =
  Eio_main.run begin fun env ->
    Dream.run env
    @@ Dream.logger
    @@ fun _ -> Dream.html "Good morning, world!"
  end
