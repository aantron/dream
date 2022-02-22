# `r-template`

<br>

Dream [*templates*](https://aantron.github.io/dream/#templates) interleave
Reason and HTML, and offer some built-in
[XSS protection](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html):

```reason
let greet = who => {
  <html>
  <body>
    <h1>Good morning, <%s who %>!</h1>
  </body>
  </html>
};

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(greet("world")))),

  ]);
```

<pre><code><b>$ cd example/r-template</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/r-template).

<br>

To use the templater, we need to add a stanza to our
[`dune`](https://github.com/aantron/dream/blob/master/example/r-template/dune)
file:

<pre><code>(executable
 (name template)
 (libraries dream))

<b>(rule
 (targets template.re)
 (deps template.eml.re)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))</b>
</code></pre>

<br>

See section *Security* in the counterpart OCaml example
[**`7-template`**](../7-template#security) for a discussion of how the templater
prevents script injection (XSS) attacks, and its limitations. That section even
disables some of the protection, and launches an XSS attack against the
template! It works equally well with this example &mdash; the templates are the
same.

<br>

**See also:**

- [**`r-template-files`**](../r-template-files#files) puts the template into a
  separate `.eml.html` file, which can help with editor problems.
- [**`r-template-stream`**](../r-template-stream#files) streams a template to a
  response.
- [**`9-error`**](../9-error#files) sets up a central error template. The
  example is in OCaml syntax.

<br>

[Up to the example index](../#reason)

<!-- TODO OWASP link; injection general link. -->
<!-- TODO Link to template syntax reference. -->
