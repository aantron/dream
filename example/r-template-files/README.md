# `r-template-files`

<br>

While templates can be written with other code in `.re` files, they can also
live in their own source files.  This can be useful as templates become larger,
or when you have many templates.

If your template file is mostly HTML, you can give it a name like
`template.eml.html`, to trigger HTML syntax highlighting by your editor.
Additionally, if you are using `ocamlformat`, the `.html` extension will
prevent errors that come from `ocamlformat` attempting to format the syntax of
the template.

This example does just that. It splits the code of the basic template example,
[**r-template**](../r-template#files), into two files. The first is the
template, in
[`template.eml.html`](https://github.com/aantron/dream/blob/master/example/r-template-files/template.eml.html):

```html
let render = param => {
  <html>
  <body>
    <h1>The URL parameter was <%s param %>!</h1>
  </body>
  </html>
};
```

After preprocessing by the templater, this file becomes `template.ml`, so it
defines a module `Template`, containing a function `Template.render`. We call
this function from the main server in
[`server.ml`](https://github.com/aantron/dream/blob/master/example/w-template-files/server.ml):

```reason
let () =
  Dream.run @@
  Dream.logger @@
  Dream.router([
    Dream.get("/:word", request =>
      Dream.param("word", request) |> Template.render |> Dream.html
    ),
  ]) @@
  Dream.not_found;
```

<pre><code><b>$ cd example/r-template-files</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

**See also:**

- [**r-template**](../r-template#files) for comments on the
[`dune` file](https://github.com/aantron/dream/blob/master/example/w-template-files/dune).
- [**7-template**](../7-template#files) for comments on [security
information](https://github.com/aantron/dream/tree/master/example/7-template#security).
- [**w-template-files**](../w-template-files) for the OCaml version of this example.

<br>

[Up to the example index](../#examples)
