# `w-server-sent-events`

<br>

In [server-sent
events](https://developer.mozilla.org/en-US/docs/Web/API/EventSource), a client
sends a request to a server, to which the server responds with header
`Content-Type: text/event-stream`, and gradually streams events.

This example sets up a message-generating loop, `message_loop`, to simulate
messages sent by other clients:

```ocaml
let rec message_loop () =
  let%lwt () = Lwt_unix.sleep (Random.float 2.) in

  incr last_message;
  let message = string_of_int !last_message in
  Dream.log "Generated message %s" message;

  server_state := message::!server_state;
  !notify ();

  message_loop ()
```

<br>

When a client connects to the example's server-sent events endpoint at
[http://localhost:8080/push](http://localhost:8080/push)
[[playground](http://dream.as/w-server-sent-events)], the server first sends any
messages that have already accumulated, and then gradually
[streams](https://aantron.github.io/dream/#streaming) more messages as they are
created.

You can see this in action either by visiting the endpoint directly, or as
interpreted by the page at [http://localhost:8080](http://localhost:8080), which
uses the browser
[`EventSource`](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)
interface to server-sent events.

<br>

**See also:**

- [**`k-websocket`**](../k-websocket#files) for WebSockets, which largely
  supersede server-sent events.
- [**`w-template-stream`**](../w-template-stream#files) for another example of
  “real-time” streaming with
  [`Dream.flush`](https://aantron.github.io/dream/#val-flush).

<br>

[Up to the example index](../#examples)

<!-- TODO OWASP link; injection general link. -->
<!-- TODO Link to template syntax reference. -->
<!-- TODO Link to the right examples section here and from all examples. -->
