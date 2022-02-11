let greet = who => {
  <html>
  <body>
    <h1>Good morning, <%s who %>!</h1>
  </body>
  </html>
};

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(greet("world")))),

  ]);
