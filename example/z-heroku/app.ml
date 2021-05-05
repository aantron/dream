let () =
  Dream.run ~interface:"0.0.0.0" ~port:(int_of_string (Sys.getenv "PORT"))
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Good morning, world!");
  ]
  @@ Dream.not_found
