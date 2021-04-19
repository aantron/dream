# `1-hello`

<br>

This project is so simple that it doesn't even log requests!

```ocaml
let () =
  Dream.run (fun _ ->
    Dream.html "Good morning, world!")
```

<br>

It's the absolute minimum Dream server. It responds to all requests with the
same text. At startup, Dream prints a message to the log, telling you where to
point your browser. Your terminal probably allows you to click the link.

<pre><code><b>$ dune exec --root . ./hello.exe</b>
08.03.21 21:17:21.471                       Running on http://localhost:8080
08.03.21 21:17:21.471                       Press ENTER to stop
</code></pre>

If you go to [http://localhost:8080](http://localhost:8080), you will, of
course, see `Good morning, world!`.

<br>

**Next steps:**

- The next example, [**`2-middleware`**](../2-middleware#files), adds a logger
  to the app.
- [**`3-router`**](../3-router#files) sends requests to different handlers,
  depending on their path.

**See also:**

- [**`r-hello`**](../r-hello#files) is a Reason syntax version of this example.
- [**`w-esy`**](../w-esy#files) wraps this example in an [esy](https://esy.sh/)
  package, for an npm-like development experience.
- [**`w-fswatch`**](../w-fswatch#files) sets up a primitive development watcher.


<br>

[Up to the tutorial index](../#readme)
