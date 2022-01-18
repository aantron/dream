let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/static/**" (Dream.static ".")
  ]
  @@ Dream.not_found
