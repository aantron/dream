# `1-hello`

<br>

This project is so simple that it doesn't even log requests!

```ocaml
let () =
  Dream.run (fun _ ->
    Dream.respond "Good morning, world!")
```

<br>

It's the absolute minimum Dream server. It responds to all requests with the
same text. At startup, it prints a message to the log, telling you where to
point your browser. The link is clickable in many terminals.

<pre><code><b>$ dune exec --root . ./hello.exe</b>
08.03.21 21:17:21.471                       Running on http://localhost:8080
08.03.21 21:17:21.471                       Press ENTER to stop
</code></pre>

If you go to [http://localhost:8080](http://localhost:8080), you will, of
course, see `Good morning, world!`.

<br>

Next steps:

- The next example, [**`2-middleware`**](../2-middleware#files) adds a *logger*
  to the app.
- [**`3-counter`**](../3-counter) is a really basic app that actually does
  something in response to requests.

<br>

[Up to the example index](../#readme)
