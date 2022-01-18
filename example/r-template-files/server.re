let () =
  Eio_main.run @@ env =>
  Dream.run(env) @@
  Dream.logger @@
  Dream.router([
    Dream.get("/:word", request =>
      Dream.param(request, "word") |> Template.render |> Dream.html
    ),
  ]) @@
  Dream.not_found;
