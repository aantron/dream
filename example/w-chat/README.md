# `w-chat`

<br>

In this example, multiple clients connect to the server by
[WebSockets](https://aantron.github.io/dream/#websockets), and the server
forwards messages between them, creating a simple chat.

The core function is called on each new WebSocket. It puts the WebSocket into a
hash table, listens for messages, and forwards them to all the other WebSockets
in the hash table:

```ocaml
let handle_client client =
  let client_id = track client in
  let rec loop () =
    match%lwt Dream.receive client with
    | Some message ->
      let%lwt () = send message in
      loop ()
    | None ->
      forget client_id;
      Dream.close_websocket client
  in
  loop ()
```

The rest of the code hooks up the client's message form to the WebSocket.

<pre><code><b>$ cd example/w-chat</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Open [http://localhost:8080](http://localhost:8080) in two tabs to get the
whole exchange started! You can also try it in the
[playground](http://dream.as/w-chat). To connect a second tab, copy out the
address from the playground's location bar, and paste it into a new tab in your
browser.

<br>

If you run code like this under HTTPS, be sure to use `wss://` for the protocol
scheme, rather than `ws://`, on the client.

<br>

**See also:**

- [**k-websocket**](../k-websocket#files) for an introduction to WebSockets.

<br>

[Up to the example index](../#examples)
