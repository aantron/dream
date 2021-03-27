let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/echo" (fun request ->
      Dream.response ""
      |> Dream.with_body_stream (fun () -> Dream.body_stream request)
      |> Lwt.return);
  ]
  @@ Dream.not_found
