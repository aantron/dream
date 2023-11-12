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
            Dream.send websocket "Good-bye!"
          | _ ->
            Dream.close_websocket websocket));

  ]
```

<pre><code><b>$ cd example/k-websocket</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Visit [http://localhost:8080](http://localhost:8080)
[[playground](http://dream.as/k-websocket)] to get the whole exchange started!

![WebSocket alert](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/websocket.png)

<br>

If you are running under HTTPS, be sure to use `wss://` for the protocol scheme,
rather than `ws://`, on the client.

You don't have to call
[`Dream.close_websocket`](https://aantron.github.io/dream/#val-close_websocket)
when you are done with the WebSocket.
[`Dream.websocket`](https://aantron.github.io/dream/#val-websocket) calls it
automatically when your callback's promise resolves or is rejected with an
exception. This example calls `Dream.close_websocket` in one branch just
because there is nothing else to do.

See [*WebSockets*](https://aantron.github.io/dream/#websockets) in the API docs.

<br>

**Last step:**

- [**`l-https`**](../l-https#files) enables HTTPS.

<br>

**See also:**

- [**`w-chat`**](../w-chat#files) is a simple WebSocket-based chat application.
- [**`w-live-reload`**](../w-live-reload#files) uses WebSockets to implement
  live reloading.
- [**`w-graphql-subscription`**](../w-graphql-subscription) does not show a
  WebSocket directly, but shows GraphQL subscriptions, which are implemented
  over WebSockets.

<br>

[Up to the tutorial index](../#readme)
