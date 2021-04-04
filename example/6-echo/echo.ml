let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/echo" (fun request ->
      let%lwt body = Dream.body request in
      Dream.respond body);
  ]
  @@ Dream.not_found
