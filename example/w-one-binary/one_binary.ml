let loader _root path _request =
  match Assets.read path with
  | None -> Dream.empty `Not_Found
  | Some asset -> Dream.respond asset

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/assets/**" (Dream.static ~loader "")
  ]
  @@ Dream.not_found
