*Middleware* is just functions that take handlers and wrap them, producing,
again handlers. This example takes the handler from [**`1-hello`**](../1-hello)
and wraps it in one of the most useful middlewares, the *logger*:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ fun _ -> Dream.respond "Good morning, world!"
```

The `@@` is just the
[standard OCaml operator](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Stdlib.html#VAL(@@))
for calling functions without nesting tons of parentheses. In fact, the above
code is the same as:

```ocaml
let () =
  Dream.run (Dream.logger (fun _ ->
    Dream.respond "Good morning, world!"))
```

But you can probably see that if you stack multiple middlewares like this, you
will end up with way too many parens! So, we opt for `@@`.

<br>

When you run this server and visit `http://localhost:8080`, you get much more
interesting (and colorful!) output:

```
$ make
08.02.21 22:19:21.126                       Running on http://localhost:8080
08.02.21 22:19:21.126                       Press ENTER to stop
08.02.21 22:19:24.927       dream.log  INFO REQ 1 GET / 127.0.0.1:58549 Mozilla/5.0 ...
08.02.21 22:19:24.928       dream.log  INFO REQ 1 200 in 2 μs
```

You can write your own messages to the log using `Dream.log`.

<br>

Where to go from here?

- [**`3-counter`**](../3-counter) calls `Dream.log` while incrementing its
  little counter.
- [**`4-catch`**](../4-catch) shows how to centralize error handling and enable
  the debugger.
