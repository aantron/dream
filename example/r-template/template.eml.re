let render = param => {
  <html>
    <body>
      <h1>The URL parameter was <%s param %>!</h1>
    </body>
  </html>
};

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/:word",
      (request =>
        Dream.param("word", request)
        |> render
        |> Dream.html)),

  ])
  @@ Dream.not_found;
