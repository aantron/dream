let home = {
  <html>
    <body>
      <p><%s Common.greet(`Server) %></p>
      <script src="/static/client.js"></script>
    </body>
  </html>
};

let () =
  Eio_main.run @@ env =>
  Dream.run(env)
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(home))),

    Dream.get("/static/**",
      Dream.static("./static")),

  ]);
