let home =
  <html>
  <body>
    <script>

    var socket = new WebSocket("ws://" + window.location.host + "/websocket");

    socket.onopen = function () {
      socket.send("Hello?");
    };

    socket.onmessage = function (e) {
      alert(e.data);
    };

    </script>
  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.html home);

    Dream.get "/websocket"
      (fun _ ->
        Dream.websocket (fun websocket ->
          match%lwt Dream.receive websocket with
          | Some "Hello?" ->
            let%lwt () = Dream.send websocket "Good-bye!" in
            Dream.close_websocket websocket
          | _ ->
            Dream.close_websocket websocket));

  ]
  @@ Dream.not_found
