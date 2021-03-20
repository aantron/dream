let () =
  Dream.run ~prefix:"/foo"
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun request ->
        Printf.ksprintf Dream.respond "Prefix: %s" (Dream.target request));

    Dream.scope "/blah" [] [
      Dream.get "/echo/:word"
        (fun request ->
          request
          |> Dream.crumb "word"
          |> Dream.respond);
    ];

  ]
  @@ fun _ ->
    Dream.respond ~status:`Not_Found ""
