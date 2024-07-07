let () = Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/static/**" (Dream.static (Eio.Stdenv.cwd env))
  ]
