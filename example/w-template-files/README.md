# `w-template-files`

<br>

This example splits the code of the basic template example,
[**`7-template`**](../7-template#files), into two files. The first is the
template, in
[`template.eml.html`](https://github.com/aantron/dream/blob/master/example/w-template-files/template.eml.html).
We use the `.html` extension because it is mostly HTML, and to prevent
`ocamlformat` from trying to format the file:

```html
let render param =
  <html>
  <body>
    <h1>The URL parameter was <%s param %>!</h1>
  </body>
  </html>
```

After preprocessing by the templater, this file becomes `template.ml`, so it
defines a module `Template`, containing a function `Template.render`. We call
this function from the main server module in
[`server.ml`](https://github.com/aantron/dream/blob/master/example/w-template-files/server.ml):

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/:word"
      (fun request ->
        Dream.param "word" request
        |> Template.render
        |> Dream.html);

  ]
```

<pre><code><b>$ cd example/w-template-files</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

**See also:**

- [**`7-template`**](../7-template#files) for comments on the [`dune`
  file](https://github.com/aantron/dream/blob/master/example/w-template-files/dune)
  and [security
  information](https://github.com/aantron/dream/tree/master/example/7-template#security).
- [**`r-template-files`**](../r-template-files) for the Reason syntax version of
  this example.

<br>

[Up to the example index](../#examples)
