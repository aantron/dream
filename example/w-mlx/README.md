# `w-mlx`

<br>

[mlx](https://github.com/ocaml-mlx/mlx), an OCaml syntax dialect which adds JSX
expressions, can be used with Dream for generating HTML. 

```ocaml
let greet ~who () =
  <html>
    <head>
      <title>"Greeting"</title>
    </head>
    <body>
      <h1>"Good morning, " (JSX.string who) "!"</h1>
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ ->
      let html = JSX.render <greet who="world" /> in
      Dream.html html)
  ]
```

<pre><code><b>$ cd example/w-mlx</b>
<b>$ opam install --deps-only --yes .</b>
<b>$ dune exec --root . ./mlx.exe</b></code></pre>

<br>

[Up to the example index](../#examples)
