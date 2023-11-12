let show_heap_size () =
  Gc.((quick_stat ()).heap_words) * 8
  |> float_of_int
  |> fun bytes -> bytes /. 1024. /. 1024.
  |> Dream.log "Heap size: %.0f MB"

let stress ?(megabytes = 1024) ?(chunk = 64) stream =
  let limit = megabytes * 1024 * 1024 in
  let chunk = chunk * 1024 in

  let chunk_a = String.make chunk 'a' in
  let chunk_b = String.make chunk 'b' in

  let start = Unix.gettimeofday () in

  let rec loop sent =
    if sent >= limit then
      let%lwt () = Dream.flush stream in
      let%lwt () = Dream.close stream in
      Lwt.return (Unix.gettimeofday () -. start)
    else
      let%lwt () = Dream.write stream chunk_a in
      let%lwt () = Dream.write stream chunk_b in
      let%lwt () = Lwt.pause () in
      loop (sent + chunk + chunk)
  in
  let%lwt elapsed = loop 0 in

  Dream.log "%.0f MB/s over %.1f s"
    ((float_of_int megabytes) /. elapsed) elapsed;
  show_heap_size ();

  Lwt.return_unit

let query_int request name =
  Dream.query request name |> Option.map int_of_string

let () =
  show_heap_size ();

  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/" (fun request ->
      Dream.stream
        ~headers:["Content-Type", "application/octet-stream"]
        (stress
          ?megabytes:(query_int request "mb")
          ?chunk:(query_int request "chunk")));

  ]
