(* TODO Definitely needs flow control. *)

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

let frame = 64 * 1024

let frame_a = String.make frame 'a'
let frame_b = String.make frame 'b'

let stress websocket =
  let limit = 1024 * 1024 * 1024 in
  let start = Unix.gettimeofday () in
  let rec loop sent =
    if sent >= limit then
      let%lwt () = Dream.close_websocket websocket in
      Lwt.return (Unix.gettimeofday () -. start)
    else
      let%lwt () = Dream.send websocket frame_a ~kind:`Binary in
      let%lwt () = Dream.send websocket frame_b ~kind:`Binary in
      let%lwt () = Lwt.pause () in
      loop (sent + frame + frame)
  in
  let%lwt elapsed = loop 0 in

  Dream.log "%.0f MB/s over %.1f s"
    ((float_of_int limit) /. elapsed /. 1024. /. 1024.) elapsed;

  Lwt.return_unit

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html home);

    Dream.get "/websocket"
      (fun _ -> Dream.websocket stress);

  ]
  @@ Dream.not_found
