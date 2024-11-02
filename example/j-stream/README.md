# `j-stream`

<br>

In example [**`6-echo`**](../6-echo#folders-and-files), we echoed `POST` requests by reading
their whole bodies into memory, and then writing them. Here, we echo request
bodies chunk by chunk:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.post "/echo" (fun request ->
      let request_stream = Dream.body_stream request in

      Dream.stream
        ~headers:["Content-Type", "application/octet-stream"]
        (fun response_stream ->
          let rec loop () =
            match%lwt Dream.read request_stream with
            | None ->
              Dream.close response_stream
            | Some chunk ->
              let%lwt () = Dream.write response_stream chunk in
              let%lwt () = Dream.flush response_stream in
              loop ()
          in
          loop ()));

  ]
```

<pre><code><b>$ cd example/j-stream</b>
<b>$ opam install --deps-only --yes .</b>
<b>$ dune exec --root . ./stream.exe</b></code></pre>

<br>

You can test it by running

```
curl -X POST http://localhost:8080/echo -T -
```

You will see the server responding immediately to each line on STDIN.

<br>

Note that you don't have to call
[`Dream.close`](https://aantron.github.io/dream/#val-close) on the stream
explicitly. [`Dream.stream`](https://aantron.github.io/dream/#val-stream)
automatically closes the stream when the callback's promise resolves or is
rejected with an exception.

See [*Streams*](https://aantron.github.io/dream/#streams) in the API docs.

<br>

**Next steps:**

- [**`k-websocket`**](../k-websocket#folders-and-files) sends and receives messages over a
  WebSocket.
- [**`l-https`**](../l-https#folders-and-files) enables HTTPS, which is very easy with
  Dream.

<br>

[Up to the tutorial index](../#readme)
