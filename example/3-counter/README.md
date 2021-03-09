This example builds on [**`2-middleware`**](../2-middleware) by showing a
visitor counter. It also prints the visit count to the log. The counter itself
is stored in an ordinary global `ref`.

<!-- TODO Link to database example. -->

```ocaml
let counter = ref 0

let () =
  Dream.run
  @@ Dream.logger
  @@ (fun _ ->
    counter := !counter + 1;
    Dream.log "The count is now %i" !counter;
    Dream.respond (Printf.sprintf "You are visitor number %i!" !counter))
```

You may see the count go up by *two* each time you visit
`http://localhost:8080`. That's probably because your browser is generating
requests for `/favicon.ico`, which we are also answering with the same handler!
In [**`4-router`**](../4-router), we will see how to assign different handlers
to different paths, and reply to missing resources like `/favicon.ico` with
`404 Not Found`.

<br>

When you visit `http://localhost:8080`, you will see this handler's own
`Dream.log` output included in the log:

```
$ make
[...]
08.02.21 22:33:59.869                       REQ 6 The count is now 6
```

Use `Dream.error`, `Dream.warning`, `Dream.info`, and `Dream.debug` to print
conditionally and with different log levels.

<!-- TODO API links -->
<!-- TODO Link to creating your own log source? Seems superfluous. -->

<br>

Where to go from here?

- [**`4-router`**](../4-router) shows how to assign different handlers to
  different paths.

<!-- TODO Go to SQL example. -->
