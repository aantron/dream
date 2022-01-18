let () =
  Eio_main.run @@ fun env ->
  Dream.run ~interface:"0.0.0.0" ~port:80 env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Dream started by systemd!");
  ]
  @@ Dream.not_found
