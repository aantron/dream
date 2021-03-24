This project is so simple that it doesn't even log requests!

```ocaml
let () =
  Dream.run (fun _ ->
    Dream.respond "Good morning, world!")
```

It's the absolute minimum Dream server. It just prints a message to the log at
startup, telling you where to point your browser:

<pre><code><b>$ make</b>
08.02.21 21:17:21.471                       Running on http://localhost:8080
08.02.21 21:17:21.471                       Press ENTER to stop
</code></pre>

If you go to [http://localhost:8080](http://localhost:8080), you will, of
course, see `Good morning, world!`.

<br>

Next steps:

- The next example, [**`2-middleware`**](../2-middleware) wraps the app with the
  logger.
- [**`3-counter`**](../3-counter) is a really basic app that actually does
  *something* in response to requests.
