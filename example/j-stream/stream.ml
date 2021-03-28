let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/echo" (fun request ->
      let response = Dream.with_stream (Dream.response "") in

      Lwt.async begin fun () ->
        let rec loop () =
          match%lwt Dream.read request with
          | Some chunk ->
            let%lwt () = Dream.write chunk response in
            let%lwt () = Dream.flush response in
            loop ()
          | None ->
            Dream.close_stream response
        in
        loop ()
      end;

      Lwt.return response);
  ]
  @@ Dream.not_found
