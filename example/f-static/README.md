# `f-static`

<br>

Run this example:

<pre><code><b>$ cd example/f-static</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

...and visit
[http://localhost:8080/static/static.ml](http://localhost:8080/static/static.ml).
You will see that it prints this example's [source
code](https://github.com/aantron/dream/blob/master/example/f-static/static.ml)!

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/static/**" (Dream.static ".")
  ]
```

<br>

That is because the example uses
[`Dream.static`](https://aantron.github.io/dream/#val-static) to serve this
very directory at `/static`! Obviously, you shouldn't do this in a real app
&mdash; serve a subdirectory instead.

<br>

The static route ends with `**`. This is a [subsite
route](https://aantron.github.io/dream/#val-router). Generally, you should
prefer [`Dream.scope`](https://aantron.github.io/dream/#val-scope) to `**`,
because [`Dream.scope`](https://aantron.github.io/dream/#val-scope) will
support router introspection, if it is added in the future.

However, `**` is exactly what it is needed for
[`Dream.static`](https://aantron.github.io/dream/#val-static). Pure
introspection of a static subsite is impossible to begin with, because the
available sub-routes depend on the actual files in the file system.

<br>

If you inspect the response headers for our request, you will see
`Content-Type: text/x-ocaml`. That is because
[`Dream.static`](https://aantron.github.io/dream/#val-static) uses
[magic-mime](https://github.com/mirage/ocaml-magic-mime) to guess
`Content-Type:` based on the extension.

You can replace the file loading behavior of
[`Dream.static`](https://aantron.github.io/dream/#val-static) by passing it a
`~loader` argument. One possibility is to use
[crunch](https://github.com/mirage/ocaml-crunch) to compile a directory right
into your Web app binary, and then serve that directory from memory with
[`Dream.static`](https://aantron.github.io/dream/#val-static)! See example
[**`w-one-binary`**](../w-one-binary#files).

You can also use `~loader` to set arbitrary headers on the response.

<br>

**Next steps:**

- [**`g-upload`**](../g-upload#files) receives files instead of serving them.
- [**`h-sql`**](../h-sql#files) runs SQL queries against a database.
- [**`w-one-binary`**](../w-one-binary#files) bundles assets into a
  self-contained binary.

<br>

[Up to the tutorial index](../#readme)
