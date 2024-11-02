# `w-dream-html`

<br>

[Dream-html](https://github.com/yawaramin/dream-html) can be used with Dream for
generating HTML. Dream-html is a library that offers functions for generating
HTML, SVG, and MathML, as well as out-of-the-box support for
[htmx](https://htmx.org/) attributes. It is closely integrated with Dream for
convenience.

```ocaml
let greet who =
  let open Dream_html in
  let open HTML in
  html [lang "en"] [
    head [] [
      title [] "Greeting";
    ];
    comment "Embedded in the HTML";
    body [] [
      h1 [] [txt "Good morning, %s!" who];
    ];
  ]

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream_html.respond (greet "world"));

  ]
```

<pre><code><b>$ cd example/w-dream-html</b>
<b>$ opam install --deps-only --yes .</b>
<b>$ dune exec --root . ./main.exe</b></code></pre>

Try it in the [playground](https://dream.as/w-dream-html).

Some notes:

- All text nodes and attributes are HTML-escaped by default for security, with
  exceptions noted in the documentation
- All text nodes and attributes accept format strings for conveniently embedding
  variables in the HTML
- Functions like `Dream_html.respond`, `Dream_html.send`, `Dream_html.csrf_tag`
  provide convenient integration with Dream
- The `<!DOCTYPE html>` prefix is automatically rendered before the `<html>` tag
- The `SVG` and `MathML` modules provide their corresponding markup. The `Hx`
  module provides htmx attributes.

<br>
<br>

**See also:**

- [**`7-template`**](../7-template#security) section *Security* on output
  security. Dream-html escapes strings by default, just as the built-in templater
  does.
- [**`w-tyxml`**](../w-tyxml#folders-and-files) is a similar library that also generates
  HTML, with different design tradeoffs.

<br>

[Up to the example index](../#examples)
