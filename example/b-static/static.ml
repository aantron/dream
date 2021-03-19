let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/static/*" (Dream.static ".")

  ]
  @@ fun _ ->
    Dream.respond ~status:`Not_Found ""
