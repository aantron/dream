let app =
  Dream.start
  @@ Dream.request_id
  @@ Dream.logger

  @@ fun _request ->
    Dream.response ~headers:["Content-Length", "6"] ()
    |> Dream.set_body "VERY KEWL"
    |> Lwt.return

let () =
  Dream.run app

(* TODO Need Content-Length middleware. *)
(* TODO Max-length middleware. *)
