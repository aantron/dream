let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/echo" (fun request ->
      Dream.stream (fun response ->
        let rec loop () =
          match%lwt Dream.read request with
          | Some chunk ->
            let%lwt () = Dream.write chunk response in
            let%lwt () = Dream.flush response in
            loop ()
          | None ->
            Dream.close_stream response
        in
        loop ()));
  ]
  @@ Dream.not_found
