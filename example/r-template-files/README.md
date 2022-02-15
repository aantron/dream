# `r-template-files`

<br>

This example splits the code of the basic template example,
[**`r-template`**](../r-template#files), into two files. The first is the
template, in
[`template.eml.html`](https://github.com/aantron/dream/blob/master/example/r-template-files/template.eml.html). We use the `.html` extension because it is
mostly HTML, and to prevent `refmt` from trying to format the file:

```html
let render = param => {
  <html>
  <body>
    <h1>The URL parameter was <%s param %>!</h1>
  </body>
  </html>
};
```

After preprocessing by the templater, this file becomes `template.re`, so it
defines a module `Template`, containing a function `Template.render`. We call
this function from the main server module in
[`server.ml`](https://github.com/aantron/dream/blob/master/example/r-template-files/server.re):

```reason
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/:word", request =>
      Dream.param("word", request)
      |> Template.render
      |> Dream.html),

  ]);
```

Because we are using the extension `.eml.html` rather than `.eml.re`, we now
have to specifically tell the templater to emit Reason syntax in our
[`dune`](https://github.com/aantron/dream/blob/master/example/r-template-files/dune)
file:

<pre><code>(rule
 (targets template.re)
 (deps template.eml.html)
 (action (run dream_eml %{deps} --workspace %{workspace_root} <b>--emit-reason</b>))</code></pre>

<br>

<pre><code><b>$ cd example/r-template-files</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

**See also:**

- [**`r-template`**](../r-template#files) for the one-file version.
- [**`7-template`**](../7-template#files) for comments on [security
  information](../7-template#security).
- [**`w-template-files`**](../w-template-files) for the OCaml version of this
  example.

<br>

[Up to the example index](../#examples)
