# `w-long-polling`

<br>

*Long polling* is a technique, largely made obsolete by
[WebSockets](../k-websocket#files), where a client sends a request, but the
server does not respond until some data is available. This delayed response
works as a sort of “push” from the client's point of view, because it comes at
a time of the server's choosing.

The example implements a long-polling client and server. The core server
function is `message_loop`:

```ocaml
let rec message_loop () =
  let%lwt () = Lwt_unix.sleep (Random.float 2.) in
  incr last_message;

  let message = string_of_int !last_message in
  Dream.log "Generated message %s" message;

  begin match !server_state with
  | Client_waiting f ->
    server_state := Messages_accumulating [];
    f message
  | Messages_accumulating list ->
    server_state := Messages_accumulating (message::list)
  end;

  message_loop ()
```

<br>

This generates a “message” on the server up to every two seconds, to simulate,
perhaps, other clients sending messages.

If there is already a client waiting for a response, the message is used to
respond to the client. If not, the message is placed in a list. The next time a
client sends a request, the messages already in the list are used to respond to
the client immediately. If a client sends the next request before any more
messages are generated, the server waits to respond &mdash; hence, “long
polling.”

Try it in the [playground](http://dream.as/w-long-polling).

<br>

**See also:**

- [**`k-websocket`**](../k-websocket#files) for a more modern way of achieving
  asynchronous client-server communication.

<br>

[Up to the example index](../#examples)
