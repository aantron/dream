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
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.html home);

    Dream.get "/websocket"
      (fun request ->
        Dream.websocket request (fun response ->
          match Dream.read response with
          | Some "Hello?" ->
            Dream.write response "Good-bye!";
            Dream.close response
          | _ ->
            Dream.close response));

  ]
  @@ Dream.not_found
