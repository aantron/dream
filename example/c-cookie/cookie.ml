let () =
  Dream.run ~secret:"foo"
  @@ Dream.logger
  @@ fun request ->
    match Dream.cookie "ui.language" request with
    | Some value ->
      Printf.ksprintf
        Dream.respond "Your preferred language is %s!" (Dream.html_escape value)

    | None ->
      Dream.response "Set language preference; come again!"
      |> Dream.set_cookie "ui.language" "ut-OP" request
      |> Lwt.return
