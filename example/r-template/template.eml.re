let greet = who => {
  <html>
  <body>
    <h1>Good morning, <%s who %>!</h1>
  </body>
  </html>
};

let () =
  Eio_main.run @@ env =>
  Dream.run(env)
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(greet("world")))),

  ])
  @@ Dream.not_found;
