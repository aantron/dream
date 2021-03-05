let app =
  Dream.start
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.content_length

  @@ fun _request ->
    Dream.response ()
    |> Dream.set_body "VERY KEWL"
    |> Lwt.return

let () =
  Dream.run app

(* TODO Max-length middleware. *)
