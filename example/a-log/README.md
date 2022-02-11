# `a-log`

<br>

This app writes custom messages to Dream's
[log](https://aantron.github.io/dream/#logging):

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun request ->
        Dream.log "Sending greeting to %s!" (Dream.client request);
        Dream.html "Good morning, world!");

    Dream.get "/fail"
      (fun _ ->
        Dream.warning (fun log -> log "Raising an exception!");
        raise (Failure "The Web app failed!"));

  ]
```

<pre><code><b>$ cd example/a-log</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

If you visit [http://localhost:8080](http://localhost:8080)
[[playground](http://dream.as/a-log)] and then
[http://localhost:8080/fail](http://localhost:8080/fail), you will find these
messages in the log, between the others:

```
26.03.21 21:25:17.383                       REQ 1 Sending greeting to 127.0.0.1:64099!
26.03.21 21:25:19.464                  WARN REQ 2 Raising an exception!
```

Note that this is on `stderr`. As you can see, the functions take
[`Printf`-style format strings](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html),
so you can quickly print values of various types to the log.

<br>

[`Dream.warning`](https://aantron.github.io/dream/#val-error) is a bit strange.
The reason it takes a callback, which waits for a `log` argument, is because if
the log threshold is higher than `` `Warning``, the callback is never called,
so the application doesn't spend any time formatting a string that it will not
print. This is the style of the [Logs](https://erratique.ch/software/logs)
library. Try calling
[`Dream.initialize_log`](https://aantron.github.io/dream/#val-initialize_log)
right before [`Dream.run`](https://aantron.github.io/dream/#val-run), to
suppress warnings:

```ocaml
Dream.initialize_log ~level:`Error ();
```

<br>

You can create named sub-logs for different parts of your application with
[`Dream.sub_log`](https://aantron.github.io/dream/#type-sub_log):

```ocaml
let my_log =
  Dream.sub_log "my.log"

let () =
  my_log.warning (fun log -> log "Hmmm...")
```

<br>

**Next steps:**

- [**`b-session`**](../b-session#files) returns Web development proper with
  session management.
- [**`c-cookie`**](../c-cookie#files) shows cookie handling in Dream.

<br>

[Up to the tutorial index](../#readme)
