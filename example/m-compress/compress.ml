let () =
  Dream.run @@ Dream.logger @@ Dream.compress
  @@ Dream.router [ Dream.get "/" (fun _ -> Dream.html "Hello World!") ]