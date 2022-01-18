open Tyxml

let greet = who =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>{Html.txt("Good morning, " ++ who ++ "!")}</h1>
    </body>
  </html>

let html_to_string = html =>
  Format.asprintf("%a", Tyxml.Html.pp(), html);

let () =
  Eio_main.run @@ env =>
  Dream.run(env)
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(html_to_string(greet("world"))))),

  ])
  @@ Dream.not_found
