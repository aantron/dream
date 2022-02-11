# `w-live-reload`

<br>

This example shows a simple live reloading setup. It works by injecting a script
into the `<head>` of HTML documents. The script opens a WebSocket back to the
server. If the WebSocket gets closed, the script tries to reconnect. When the
server comes back up, the client is able to reconnect, and reloads itself.

```js
var socketUrl = "ws://" + location.host + "/_live-reload"
var socket = new WebSocket(socketUrl);

socket.onclose = function(event) {
  const intervalMs = 100;
  const attempts = 100;
  let attempt = 0;

  function reload() {
    ++attempt;

    if(attempt > attempts) {
      console.error("Could not reconnect to server");
      return;
    }

    reconnectSocket = new WebSocket(socketUrl);

    reconnectSocket.onerror = function(event) {
      setTimeout(reload, intervalMs);
    };

    reconnectSocket.onopen = function(event) {
      location.reload();
    };
  };

  reload();
};
```

The injection is done by a small middleware:

```ocaml

let inject_live_reload_script inner_handler request =
  let%lwt response = inner_handler request in

  match Dream.header "Content-Type" response with
  | Some "text/html; charset=utf-8" ->
    let%lwt body = Dream.body response in
    let soup =
      Markup.string body
      |> Markup.parse_html ~context:`Document
      |> Markup.signals
      |> Soup.from_signals
    in

    begin match Soup.Infix.(soup $? "head") with
    | None ->
      Lwt.return response
    | Some head ->
      Soup.create_element "script" ~inner_text:live_reload_script
      |> Soup.append_child head;
      response
      |> Dream.with_body (Soup.to_string soup)
      |> Lwt.return
    end

  | _ ->
    Lwt.return response
```

The example server just wraps a single page at `/` with the middleware. The page
displays a tag that changes each time it is loaded:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ inject_live_reload_script
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.random 3
      |> Dream.to_base64url
      |> Printf.sprintf "Good morning, world! Random tag: %s"
      |> Dream.html);

    Dream.get "/_live-reload" (fun _ ->
      Dream.websocket (fun socket ->
        let%lwt _ = Dream.receive socket in
        Dream.close_websocket socket));

  ]
```

<pre><code><b>$ cd example/w-live-reload</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b>
</code></pre>

<br>

After the server starts, go to [http://localhost:8080](http://localhost:8080).
You will see a page like

```
Good morning, world! Random tag: A7DK
```

Stop the server with Ctrl+C, and then start it again. The browser will
automatically reload, and you will see something like

```
Good morning, world! Random tag: jRak
```

<br>

This example plays very well with [**`w-fswatch`**](../w-fswatch#files), which
shows how to rebuild and restart a development server every time sources are
modified in the file system. Combining the two examples, it is possible to
propagate reloading all the way to the client, whenever any of the server's
source code changes.

<br>

**See also:**

- [**`k-websocket`**](../k-websocket#files) introduces WebSockets.
- [**`w-fswatch`**](../w-fswatch#files) rebuilds and restarts a server each
  time its source code changes.

<br>

[Up to the example index](../#examples)
