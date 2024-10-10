let () =
  Lwt_engine.set (new Lwt_engine.select);

  print_endline "example started, stdout";
  prerr_endline "example started, stderr";

  Dream.router
    [
      Dream.get "/" (fun _ ->
          prerr_endline "get";
          Lwt.return
            (Dream.response
               ~headers:[ ("Content-Type", "text/plain") ]
               "On macOS I leak.\n"));
    ]
  |> Dream.logger |> Dream.run ~port:8080
