let greet who =
  let open Tyxml.Html in
  html
    (head (title (txt "Greeting")) [])
    (body [
      h1 [
        txt "Good morning, "; txt who; txt "!";
      ]
    ])

let html_to_string html =
  Format.asprintf "%a" (Tyxml.Html.pp ()) html

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html (html_to_string (greet "world")));

  ]
  @@ Dream.not_found
