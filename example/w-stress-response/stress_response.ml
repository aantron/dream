(* TODO Once concurrent writing is supported, send N concurrent streams and test
   for fairness. *)
(* TODO There seems to be some GC thrashing and even page thrashing or similar
   with very large streams, probably due to buffer growth from a lack of
   server-side flow control. *)

let stress ?(megabytes = 1024) ?(chunk = 64) response =
  let limit = megabytes * 1024 * 1024 in
  let chunk = chunk * 1024 in

  let chunk_a = String.make chunk 'a' in
  let chunk_b = String.make chunk 'b' in

  let start = Unix.gettimeofday () in

  let rec loop sent =
    if sent >= limit then
      let%lwt () = Dream.flush response in
      let%lwt () = Dream.close_stream response in
      Lwt.return (Unix.gettimeofday () -. start)
    else
      let%lwt () = Dream.write response chunk_a in
      let%lwt () = Dream.write response chunk_b in
      let%lwt () = Lwt.pause () in
      loop (sent + chunk + chunk)
  in
  let%lwt elapsed = loop 0 in

  Dream.log "%.0f MB/s over %.1f s"
    ((float_of_int megabytes) /. elapsed) elapsed;

  Lwt.return_unit

let query_int name request =
  Dream.query name request |> Option.map int_of_string

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/" (fun request ->
      Dream.stream
        ~headers:["Content-Type", "application/octet-stream"]
        (stress
          ?megabytes:(query_int "mb" request)
          ?chunk:(query_int "chunk" request)));

  ]
  @@ Dream.not_found
