let echo request response =
  let rec loop () =
    match%lwt Dream.read request with
    | None ->
      Dream.close_stream response
    | Some chunk ->
      let%lwt () = Dream.write chunk response in
      let%lwt () = Dream.flush response in
      loop ()
  in
  loop ()

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.post "/echo" (fun request ->
      Dream.stream
        ~headers:["Content-Type", "application/octet-stream"]
        (echo request));

  ]
  @@ Dream.not_found
