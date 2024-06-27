let greet = (~who, ()) =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>{Jsx.txt("Good morning, " ++ who ++ "!")}</h1>
    </body>
  </html>;

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(Jsx.render(<greet ~who="world" />))))),

  ]);
