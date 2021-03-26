let my_logger inner_handler request =
  Dream.log "%s %s"
    (Dream.method_to_string (Dream.method_ request))
    (Dream.target request);

  try%lwt
    let%lwt response = inner_handler request in

    let status = Dream.status response in
    Dream.log "%i %s"
      (Dream.status_to_int status)
      (Dream.status_to_string status);

    Lwt.return response

  with exn ->
    Dream.error (fun log -> log "%s" (Printexc.to_string exn));
    raise exn

let () =
  Dream.run
  @@ my_logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The web app failed!"));

  ]
  @@ Dream.not_found
