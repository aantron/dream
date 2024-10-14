let greet who =
  let open Dream_html in
  let open HTML in
  html [lang "en"] [
    head [] [
      title [] "Greeting";
    ];
    comment "Embedded in the HTML";
    body [] [
      h1 [] [txt "Good morning, %s!" who];
    ];
  ]

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream_html.respond (greet "world"));

  ]

