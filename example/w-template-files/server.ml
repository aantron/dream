let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/:word"
      (fun request ->
        Dream.param request "word"
        |> Template.render
        |> Dream.html);

  ]
  @@ Dream.not_found
