let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/:word"
      (fun request ->
        Dream.param "word" request
        |> Template.render
        |> Dream.html);

  ]
  @@ Dream.not_found
