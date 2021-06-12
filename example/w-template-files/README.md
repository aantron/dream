# `w-template-files`

Dream [*templates*](https://aantron.github.io/dream/#templates) allow
interleaving OCaml and HTML in a straightforward way, and help with
[XSS protection](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html).

While templates can be written with other code in `.ml` files, they
can also live in their own source files.  This can be useful as
templates become larger, or when you have many templates.

If your template file is mostly HTML, you can give it a name like
`template.eml.html`, to trigger HTML syntax highlighting by your
editor.  Additionally, if you are using `ocamlformat`, the `.html`
extension will prevent errors that come from `ocamlformat` attempting
to format the HTML in the template.  (See [this
issue](https://github.com/aantron/dream/issues/55) for more
information.)

## Files

### `template.eml.html`

```ocaml
let render param =
  <html>
  <body>
    <h1>The URL parameter was <%s param %>!</h1>
  </body>
  </html>
```

You will be able to access this function as `Template.render` in the
`server.ml` file.

The substitution, `<%s param %>`, uses [`Printf` conversion
specifications](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html)
from the standard library. So, you can do things like this:

- `<%i my_int %>` to print an OCaml `int`.
- `<%02x my_hex_int %>` to print an `int` in hexadecimal, with at
  least two characters, left-padded with zeroes.

### `server.ml`

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/:word"
      (fun request ->
        Dream.param "word" request
		(* This is the `render` function we defined in
		   `template.eml.html`. *)
        |> Template.render
        |> Dream.html);

  ]
  @@ Dream.not_found
```

### dune

This requires a bit more setup in our
[`dune`](https://github.com/aantron/dream/blob/master/example/w-template-files/dune)
file to run the template preprocessor.  Note that the `render`
function defined in `template.eml.html` will be available to the
server code as `Template.render` as we set the `targets template.ml`
in the `rule` stanza in the dune file.

```
(executable
 (name server)
 (libraries dream))

(rule
 (targets template.ml)
 (deps template.eml.html)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))

(data_only_dirs _esy esy.lock)
```

## Run it

<pre><code><b>$ cd example/w-template-files</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Now, you should be able to browse to
[http://localhost:8080/dream](http://localhost:8080/dream) and see the
response.  Try changing `dream` to something else and watch how the
response changes!

## Security

See section *Security* in the counterpart OCaml example
[**`7-template`**](../7-template#security) for a discussion of how the
templater prevents script injection (XSS) attacks, and its
limitations. That section even disables some of the protection, and
launches an XSS attack against the template! It works equally well
with this example &mdash; the templates are the same.

## See also

- [**`w-tyxml`**](../w-tyxml#files) shows how to use
  [TyXML](https://github.com/ocsigen/tyxml), a different templater
  that uses OCaml's type system to prevent emitting many kinds of
  invalid HTML.
- [**`r-tyxml`**](../r-tyxml#files) if you are using Reason. You can
  use TyXML with JSX syntax server-side!
- [**`w-template-stream`**](../w-template-stream#files) streams
  templates to responses, instead of building up complete response
  strings.
- [**`r-template`**](../r-template#files) is a Reason syntax version
  of this example.
- [**`r-template-stream`**](../r-template-stream#files) streams a
  template to a response.

<br>

[Up to the tutorial index](../#readme)
