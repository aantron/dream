let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.livereload
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.random 3
      |> Dream.to_base64url
      |> Printf.sprintf "Good morning, world! Random tag: %s"
      |> Dream.html);

  ]
