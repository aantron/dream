let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.post "/echo" (fun request ->
      let request_stream = Dream.body_stream request in

      Dream.stream
        ~headers:["Content-Type", "application/octet-stream"]
        (fun response_stream ->
          let rec loop () =
            match%lwt Dream.read request_stream with
            | None ->
              Dream.close response_stream
            | Some chunk ->
              let%lwt () = Dream.write response_stream chunk in
              let%lwt () = Dream.flush response_stream in
              loop ()
          in
          loop ()));

  ]
