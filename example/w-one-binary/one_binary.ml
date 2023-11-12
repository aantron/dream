let loader _root path _request =
  match Assets.read path with
  | None -> Dream.empty `Not_Found
  | Some asset -> Dream.respond asset

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/assets/**" (Dream.static ~loader "")
  ]
