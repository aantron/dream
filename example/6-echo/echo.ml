let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/echo" (fun request ->
      Lwt.map Dream.response (Dream.body request));
  ]
  @@ Dream.not_found
