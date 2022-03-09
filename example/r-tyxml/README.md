# `r-tyxml`

<br>

[TyXML](https://github.com/ocsigen/tyxml) can be used
[[playground](http://dream.as/r-tyxml)] together with Reason's built-in JSX
syntax for generating HTML on the server:

```reason
open Tyxml

let greet = who =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>{Html.txt("Good morning, " ++ who ++ "!")}</h1>
    </body>
  </html>

let html_to_string = html =>
  Format.asprintf("%a", Tyxml.Html.pp(), html);

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(html_to_string(greet("world"))))),

  ]);
```

<pre><code><b>$ cd example/r-tyxml</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

To get this, we depend on package `tyxml-jsx` in
[`esy.json`](https://github.com/aantron/dream/blob/master/example/r-tyxml/esy.json):

<pre><code>{
  "dependencies": {
    "@opam/dream": "1.0.0~alpha4",
    "@opam/dune": "^2.0",
    "@opam/reason": "^3.7.0",
    "@opam/tyxml": "*",
    <b>"@opam/tyxml-jsx": "*",</b>
    "ocaml": "4.12.x"
  },
  "scripts": {
    "start": "dune exec --root . ./tyxml.exe"
  }
}
</code></pre>

and add `tyxml-jsx` to our preprocessor list in
[`dune`](https://github.com/aantron/dream/blob/master/example/r-tyxml/dune):

<pre><code>(executable
 (name tyxml)
 (libraries dream tyxml)
 <b>(preprocess (pps lwt_ppx tyxml-jsx)))</b>
</code></pre>

If you miss adding `tyxml-jsx` to `dune`, you may get a message like

```
File "Main.re", line 6, characters 2-7:
6 |   <html>
      ^^^^^
Error: Unbound value html
```

<br>

**See also:**

- [**`w-tyxml`**](../w-tyxml#files) for an introduction to TyXML.
- [**`7-template`**](../7-template#security) section *Security* on output
  security. TyXML escapes strings by default, just as the built-in templater
  does.
- [*TyXML JSX Syntax*](https://ocsigen.org/tyxml/latest/manual/jsx) is the
  reference for TyXML's JSX support.

<br>

[Up to the example index](../#reason)
