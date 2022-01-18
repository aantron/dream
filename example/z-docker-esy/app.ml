let () =
  Eio_main.run @@ fun env ->
  Dream.run ~interface:"0.0.0.0" env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ ->
      Dream.html "Dream started by Docker Compose, built with esy!");
  ]
  @@ Dream.not_found
