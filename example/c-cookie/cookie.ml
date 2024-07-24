let () = Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.set_secret "foo"
  @@ Dream.logger
  @@ fun request ->

    match Dream.cookie request "ui.language" with
    | Some value ->
      Printf.ksprintf
        Dream.html "Your preferred language is %s!" (Dream.html_escape value)

    | None ->
      let response = Dream.response "Set language preference; come again!" in
      Dream.add_header response "Content-Type" Dream.text_html;
      Dream.set_cookie response request "ui.language" "ut-OP";
      response
