let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/:word", request =>
      Dream.param(request, "word")
      |> Template.render
      |> Dream.html),

  ]);
