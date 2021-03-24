let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/echo/:word"
      (fun request ->
        Dream.respond (Dream.param "word" request));

  ]
  @@ fun _ ->
    Dream.empty `Not_Found
