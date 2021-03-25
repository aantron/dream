# `2-middleware`

<br>

*Middleware* is just functions that take handlers and wrap them, producing
handlers that do a little bit more. This example takes the handler from
[**`1-hello`**](../1-hello/#files) and wraps it in one of the most useful
middlewares, the *logger*:

```ocaml
let () =
  Dream.run
    (Dream.logger (fun _ ->
      Dream.respond "Good morning, world!"))
```

<br>

However, as you can see, the more middlewares we stack on top of each other
like this, the more parentheses and indentation we will end up with! To keep
the code tidy, we use `@@`, the
[standard OCaml operator](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Stdlib.html#VAL(@@)) for calling functions without parentheses. So, the actual
code in this example looks like this:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ fun _ ->
    Dream.respond "Good morning, world!"
```

<br>

When you run this server and visit
[http://localhost:8080](http://localhost:8080), you get much more interesting
(and colorful!) output:

<pre><code><b>$ dune exec --root . ./middleware.exe</b>
08.03.21 22:19:21.126                       Running on http://localhost:8080
08.03.21 22:19:21.126                       Press ENTER to stop
08.03.21 22:19:24.927       dream.log  INFO REQ 1 GET / 127.0.0.1:58549 Mozilla/5.0 ...
08.03.21 22:19:24.928       dream.log  INFO REQ 1 200 in 217 μs
</code></pre>

<!-- TODO Link to Dream.log. -->

You can write your own messages to the log using `Dream.log`. See example
[**`9-logging`**](../9-logging/#files) for more logging options. Now that we
have the logger, we will use it in all other examples, even though it's not
really necessary &mdash; it just makes it much easier to see what is going on.

<br>

There's not much else to middlewares &mdash; they are really just functions
from handlers to handlers, so you can create them anywhere. Example
[**`4-counter`**](../4-counter/#files) already shows a simple custom middleware.
There are also more complicated middlewares defined in

- [**`m-locals`**](../m-locals/#files),
- [**`w-auto-reload`**](../w-auto-reload/#files), and
- [**`w-index-html`**](../w-index-html/#files).

<!-- TODO Fill out this list; probably a-promise belongs here. -->

<br>

**Next steps:**

- The next example, [**`3-router`**](../3-router/#files), shows *routes*, the
  other way to build up handlers in Dream.
- [**`4-counter`**](../4-counter/#files) builds the first custom middleware.

<br>

[Up to the tutorial index](../#readme)
