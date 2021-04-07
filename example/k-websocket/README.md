# `k-websocket`

<br>

In this example, the client connects to the server by a
[WebSocket](https://aantron.github.io/dream/#websockets). They then follow a
silly protocol: if the client sends `"Hello?"`, the server responds with
`"Good-bye!"`. The client displays the message in an alert box:

```ocaml
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
```

<pre><code><b>$ dune exec --root . ./websocket.exe</b></code></pre>

<br>

Visit [http://localhost:8080](http://localhost:8080) to get the whole exchange
started!

![WebSocket alert](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/websocket.png)

See [*WebSockets*](https://aantron.github.io/dream/#websockets) in the API docs.

<br>

**Next steps:**

- [**`l-https`**](../l-https#files) enables HTTPS.
- [**`m-crypto`**](../m-crypto) encrypts strings using Dream's cryptographic
  helpers.

<br>

[Up to the tutorial index](../#readme)
