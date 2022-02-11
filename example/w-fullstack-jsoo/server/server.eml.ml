let home =
  <html>
    <body id="body">
      <p><%s Common.greet `Server %></p>
      <script src="/static/client.js"></script>
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html home);

    Dream.get "/static/**"
      (Dream.static "./static");

  ]
