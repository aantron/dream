# `j-stream`

<br>

In example [**`6-echo`**](../6-echo#files), we echoed `POST` requests by reading
their whole bodies into memory, and then writing them. Here, we echo request
bodies chunk by chunk:

```ocaml
let echo request response =
  let rec loop () =
    match%lwt Dream.read request with
    | None ->
      Dream.close_stream response
    | Some chunk ->
      let%lwt () = Dream.write response chunk in
      let%lwt () = Dream.flush response in
      loop ()
  in
  loop ()

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.post "/echo" (fun request ->
      Dream.stream
        ~headers:["Content-Type", "application/octet-stream"]
        (echo request));

  ]
  @@ Dream.not_found
```

<pre><code><b>$ cd example/j-stream</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

You can test it by running

```
curl -X POST http://localhost:8080/echo -T -
```

You will see the server responding immediately to each line on STDIN.

See [*Streaming*](https://aantron.github.io/dream/#streaming) in the API docs.

<br>

**Next steps:**

- [**`k-websocket`**](../k-websocket#files) sends and receives messages over a
  WebSocket.
- [**`l-https`**](../l-https#files) enables HTTPS, which is very easy with
  Dream.

<br>

[Up to the tutorial index](../#readme)
