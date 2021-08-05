let () =
  Dream.run @@
  Dream.logger @@
  Dream.router([
    Dream.get("/:word", request =>
      Dream.param("word", request) |> Template.render |> Dream.html
    ),
  ]) @@
  Dream.not_found;
