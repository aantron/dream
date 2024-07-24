let greet = (~who, ()) =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>{JSX.string("Good morning, " ++ who ++ "!")}</h1>
    </body>
  </html>;

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(JSX.render(<greet who="world" />)))),

  ]);
