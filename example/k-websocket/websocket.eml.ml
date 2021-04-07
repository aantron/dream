let home =
  <html>
    <body>
      <script>

      var socket = new WebSocket("ws://localhost:8080/websocket");

      socket.onopen = function () {
        socket.send("Hello?");
      };

      socket.onmessage = function (e) {
        alert(e.data);
      }

      </script>
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond home);

    Dream.get "/websocket"
      (fun _ ->
        Dream.websocket (fun websocket ->
          match%lwt Dream.receive websocket with
          | Some "Hello?" ->
            let%lwt () = Dream.send "Good-bye!" websocket in
            Dream.close_websocket websocket
          | _ ->
            Dream.close_websocket websocket));

  ]
  @@ Dream.not_found
