let () = Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [

    Dream.post "/echo" (fun request ->
      let body = Dream.body request in
      Dream.respond
        ~headers:["Content-Type", "application/octet-stream"]
        body);

  ]
