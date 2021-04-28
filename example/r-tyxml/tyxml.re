open Tyxml

let render = path_param =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>(Html.txt(path_param))</h1>
    </body>
  </html>

let html_to_string = html =>
  Format.asprintf("%a", Tyxml.Html.pp(), html);

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/:word",
      (request =>
        render(Dream.param("word", request))
        |> html_to_string
        |> Dream.html)),

  ])
  @@ Dream.not_found
