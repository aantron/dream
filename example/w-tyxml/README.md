# `w-tyxml`

<br>

[TyXML](https://github.com/ocsigen/tyxml) can be used with Dream for generating
HTML. Individual functions in TyXML, such as `html` and `h1`, are typed in a
way that prevents many kinds of incorrect usage. For example, you cannot nest
`h1` directly inside `html` &mdash; there must be at least an intervening
`body`.

```ocaml
let render path_param =
  let open Tyxml.Html in
  html
    (head (title (txt "Home")) [])
    (body [
      h1 [
        txt path_param
      ]
    ])

let html_to_string html =
  Format.asprintf "%a" (Tyxml.Html.pp ()) html

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/:word"
      (fun request ->
        render (Dream.param "word" request)
        |> html_to_string
        |> Dream.respond);

  ]
  @@ Dream.not_found
```

<pre><code><b>dune exec --root . ./tyxml.exe</b></code></pre>

<br>

TyXML offers two syntax extensions for making the templates look nicer. The
[HTML syntax](https://ocsigen.org/tyxml/latest/manual/ppx) looks like this:

```ocaml
open Tyxml

let%html render path_param = {|
  <html>
    <head><title>Home</title></head>
    <body>
      <h1>|} [Html.txt path_param] {|</h1>
    </body>
  </html>|}
```

The TyXML [JSX syntax](https://ocsigen.org/tyxml/latest/manual/jsx) looks like
this, combined with Reason for the surrounding language:

```reason
open Tyxml

let render = path_param =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>(Html.txt(path_param))</h1>
    </body>
  </html>
```

<br>

Note: TyXML is able to serialize HTML straight into a response body stream,
rather than into an intermediary string. However, Dream doesn't expose a
convenient way for TyXML to do so at the present time. If you need support for
this, please [open an issue](https://github.com/aantron/dream/issues).

<br>

**See also:**

- [**`7-template`**](../7-template#security) section *Security* on output
  security. TyXML escapes strings by default, just as the built-in templater
  does.

<br>

[Up to the tutorial index](../#examples)
