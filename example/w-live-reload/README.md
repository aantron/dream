# `w-live-reload`

<br>

This example shows a simple live reloading setup using the `Dream.livereload`
middleware. It works by injecting a script into the `<head>` of HTML documents.
The script opens a WebSocket back to the server. If the WebSocket gets closed,
the script tries to reconnect. When the server comes back up, the client is able
to reconnect and reloads itself.

The example server just wraps a single page at `/` with the `Dream.livereload` middleware. The page
displays a tag that changes each time it is loaded:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.livereload
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.random 3
      |> Dream.to_base64url
      |> Printf.sprintf "Good morning, world! Random tag: %s"
      |> Dream.html);

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

This example plays very well with [**`w-watch`**](../w-watch#files), which shows
how to rebuild and restart a development server every time sources are modified
in the file system. Combining the two examples, it is possible to propagate
reloading all the way to the client, whenever any of the server's source code
changes.

<br>

**See also:**

- [**`k-websocket`**](../k-websocket#files) introduces WebSockets.
- [**`w-watch`**](../w-watch#files) rebuilds and restarts a server each
  time its source code changes.

<br>

[Up to the example index](../#examples)
