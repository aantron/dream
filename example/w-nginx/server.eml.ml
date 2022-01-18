let home =
  <html>
  <body>
    <h1>Greetings from the Dream app!</h1>
    <img
      src="/assets/camel.jpeg"
      alt="A silly camel.">
  </body>
  </html>

let () =
  Eio_main.run @@ fun env ->
  Dream.run ~interface:"0.0.0.0" ~port:8081 env
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _request -> Dream.html home)
  ]
  @@ Dream.not_found
