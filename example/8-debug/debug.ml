let () = Eio_main.run @@ fun env ->
  Dream.run ~error_handler:Dream.debug_error_handler env
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/bad"
      (fun _ ->
        Dream.empty `Bad_Request);

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The Web app failed!"));

  ]
