# Templates

Dream offers a nice way to write HTML interleaved with OCaml:

```ocaml
let simple_page message =
  <html>
    <body>
      <p>The message is: <%s message %></p>
    <body>
  </html>
```

Here, `simple_page` is a function `string -> string`. You can even abuse this to create complete a complete apps in one source file, templates included. The example [6-template ↪][example] does just that!

[example]: https://github.com/aantron/dream/tree/master/example/6-template

```ocaml
let show_count count =
  <html>
    <body>
      <h1>You are visitor number <%i count %>!</h1>
    </body>
  </html>

let counter =
  ref 0

let () =
  Dream.run
  @@ Dream.logger
  @@ (fun _ ->
    counter := !counter + 1;
    Dream.respond (show_count !counter))
```

This can be most useful when just getting started on a project.

## Dune integration

sdgsdfg

## Syntax

sdfgdsg

## Tag generators


## TODO

- Syntax and explanation.
- Show Dune integration.
- Link to example project.
- Explain escaping.
- Tag helpers.
- Link back up to `dream.mli`.
- But first, see how much of this can be written in the `.mli`.
- Probably need a better lexer for templates.
- TODO These docs are probably blocked on tag and escape module development. It may be best to write them inside `tag.mli`.
