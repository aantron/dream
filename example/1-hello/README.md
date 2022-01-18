# `1-hello`

<br>

This project is so simple that it doesn't even log requests!

```ocaml
let () =
  Eio_main.run (fun env ->
    Dream.run env (fun _ ->
      Dream.html "Good morning, world!")
  )
```

<br>

It's the absolute minimum Dream server. It responds to all requests with the
same text. At startup, Dream prints a message to the log, telling you where to
point your browser. Your terminal probably makes the link clickable.

<pre><code><b>$ cd example/1-hello</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b>
08.03.21 21:17:21.471                       Running at http://localhost:8080
08.03.21 21:17:21.471                       Type Ctrl+C to stop
</code></pre>

If you go to [http://localhost:8080](http://localhost:8080), you will, of
course, see `Good morning, world!`. You can also try it in the [Dream
Playground](http://dream.as/1-hello).

<br>

If you'd like to copy out the server binary, you can do it like this:

<pre><code><b>$ npx esy cp '#{self.target_dir}/default/hello.exe' .
</b></code></pre>

The name will change as you go through the tutorial examples. It's always the
name of the `.ml` file, but with `.ml` changed to `.exe`.

<br>

A Dream server runs in an [Eio](https://github.com/ocaml-multicore/eio) event loop,
which is created by `Eio_main.run`.

<br>

**Next steps:**

- The next example, [**`2-middleware`**](../2-middleware#files), adds a logger
  to the app.
- [**`3-router`**](../3-router#files) sends requests to different handlers,
  depending on their path.

<br>

**See also:**

- [**`r-hello`**](../r-hello#files) is a Reason syntax version of this example.
- [**`w-esy`**](../w-esy#files) gives more detail on the [esy](https://esy.sh/)
  packaging.
- [**`w-fswatch`**](../w-fswatch#files) sets up a primitive development watcher.


<br>

[Up to the tutorial index](../#readme)
