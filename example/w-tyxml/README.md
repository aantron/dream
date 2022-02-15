# `w-tyxml`

<br>

[TyXML](https://github.com/ocsigen/tyxml) can be used with Dream for generating
HTML. Individual functions in TyXML, such as `html` and `h1`, are typed in a
way that prevents many kinds of incorrect usage. For example, you cannot nest
`h1` directly inside `html` &mdash; there must be at least an intervening
`body`.

```ocaml
let greet who =
  let open Tyxml.Html in
  html
    (head (title (txt "Greeting")) [])
    (body [
      h1 [
        txt "Good morning, "; txt who; txt "!";
      ]
    ])

let html_to_string html =
  Format.asprintf "%a" (Tyxml.Html.pp ()) html

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html (html_to_string (greet "world")));

  ]
```

<pre><code><b>$ cd example/w-tyxml</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/w-tyxml).

<br>

## JSX

When using Reason, TyXML supports JSX, through package
[`tyxml-jsx`](https://ocsigen.org/tyxml/latest/manual/jsx). See
[**`r-tyxml`**](../r-tyxml#files) for a complete example, including Dune
metadata.

```reason
open Tyxml

let greet = who =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>{Html.txt("Good morning, " ++ who ++ "!")}</h1>
    </body>
  </html>
```

<br>

## HTML syntax

Package [`tyxml-ppx`](https://ocsigen.org/tyxml/latest/manual/ppx) offers an
HTML syntax, which can be used with either Reason or OCaml:

```ocaml
open Tyxml

let%html greet who = {|
  <html>
    <head><title>Home</title></head>
    <body>
      <h1>|}[Html.txt ("Good morning, " ^ who ^ "!")]{|</h1>
    </body>
  </html>|}
```

To use `tyxml-ppx`, be sure to include it in the
[`dune`](https://github.com/aantron/dream/blob/master/example/w-tyxml/dune)
file:

<pre><code>(executable
 (name tyxml)
 (libraries dream tyxml)
 (preprocess (pps lwt_ppx <b>tyxml-ppx</b>)))
</code></pre>

<br>
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
- [**`r-tyxml`**](../r-tyxml#files) is the Reason and JSX version of this
  example.

<br>

[Up to the example index](../#examples)
