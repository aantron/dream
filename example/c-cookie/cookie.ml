let () =
  Dream.run ~secret:"foo"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun request ->
      match Dream.cookie "ui.language" request with
      | Some value ->
        Printf.ksprintf
          Dream.response "Your preferred language is %s! Your cookie has been removed." (Dream.html_escape value)
        |> Dream.drop_cookie "ui.language" request
        |> Lwt.return

      | None ->
        Dream.response "Set language preference; come again!"
        |> Dream.add_header "Content-Type" Dream.text_html
        |> Dream.set_cookie "ui.language" "ut-OP" request
        |> Lwt.return
      )
  ]
  @@ Dream.not_found
