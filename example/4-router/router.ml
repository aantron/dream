let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/echo/:word"
      (fun request ->
        request
        |> Dream.crumb "word"
        |> Dream.respond);

  ]
  @@ fun _ ->
    Dream.respond ~status:`Not_Found ""
