(* TODO Definitely needs flow control. *)

open Eio.Std

let home =
  <html>
    <body>
      <script>

      function socket() {
        var websocket = new WebSocket("ws://localhost:8080/websocket");

        websocket.onmessage = function () {
          console.log("message");
        }

        websocket.onclose = function () {
          console.log("closed");
        };
      }

      socket();
      socket();
      socket();
      socket();

      </script>
    </body>
  </html>

let show_heap_size () =
  Gc.((quick_stat ()).heap_words) * 8
  |> float_of_int
  |> fun bytes -> bytes /. 1024. /. 1024.
  |> Dream.log "Heap size: %.0f MB"

let frame = 64 * 1024

let frame_a = String.make frame 'a'
let frame_b = String.make frame 'b'

let stress websocket =
  let limit = 1024 * 1024 * 1024 in
  let start = Unix.gettimeofday () in
  let rec loop sent =
    if sent >= limit then (
     Dream.close_websocket websocket;
      Unix.gettimeofday () -. start
    ) else (
      Dream.send websocket frame_a ~text_or_binary:`Binary;
      Dream.send websocket frame_b ~text_or_binary:`Binary;
      Fiber.yield ();
      loop (sent + frame + frame)
    )
  in
  let elapsed = loop 0 in

  Dream.log "%.0f MB/s over %.1f s"
    ((float_of_int limit) /. elapsed /. 1024. /. 1024.) elapsed;
  show_heap_size ()

let () =
  show_heap_size ();

  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html home);

    Dream.get "/websocket"
      (fun _ -> Dream.websocket stress);

  ]
