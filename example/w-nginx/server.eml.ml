let body =
  <html>
  <body>
  <h1>Greetings from the Dream Server!</h1>
  <a href="http://ocaml.org">
  <img src="/static/ocaml.png"
       alt="The OCaml logo."
       style="border: none; width: 150px;" />
  </a>
  </body>
  </html>


let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _request -> Dream.html body)
  ]
  @@ Dream.not_found
