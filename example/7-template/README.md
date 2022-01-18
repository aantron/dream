# `7-template`

<br>

Dream [*templates*](https://aantron.github.io/dream/#templates) allow
interleaving OCaml and HTML in a straightforward way, and help with
[XSS protection](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html).
After looking at a secure example, we will [weaken and then exploit
it](#security).

```ocaml
let render param =
  <html>
  <body>
    <h1>The URL parameter was <%s param %>!</h1>
  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/:word"
      (fun request ->
        Dream.param "word" request
        |> render
        |> Dream.html);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ cd example/7-template</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

This requires a bit more setup in our
[`dune`](https://github.com/aantron/dream/blob/master/example/7-template/dune)
file to run the template preprocessor:

<pre><code>(executable
 (name template)
 (libraries dream))

<b>(rule
 (targets template.ml)
 (deps template.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))</b>
</code></pre>

<br>

The substitution, `<%s param %>`, uses
[`Printf` conversion specifications](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html)
from the standard library. So, you can do things like this:

- `<%i my_int %>` to print an OCaml `int`.
- `<%02x my_hex_int %>` to print an `int` in hexadecimal, with at least two characters, left-padded with zeroes.

<br>

If your template file is mostly HTML, you can give it a name like
`template.eml.html`, to trigger HTML syntax highlighting by your editor.

<br>

## Security

The template automatically passes strings through
[`Dream.html_escape`](https://aantron.github.io/dream/#val-html_escape) before
inserting them into the output. This only applies to formats that can emit
dangerous characters: `%s`, `%S`, `%c`, `%C`, `%a`, and `%t`.

You can suppress the hidden call to
[`Dream.html_escape`](https://aantron.github.io/dream/#val-html_escape) using
`!`; for example, `<%s! param %>`. You may want to do this if your data is
already escaped, or if it is safe for some other reason. But be careful!

<br>

To show the danger, let's launch a **script injection (XSS) attack** against
this tiny Web app! First, go to
[`template.eml.ml`](https://github.com/aantron/dream/blob/master/example/7-template/template.eml.ml#L4),
change the substitution to `<%s! param %>`, and restart the app. You can also
make the edit in the [playground](http://dream.as/7-template/foo). Then,
visit
this highly questionable URL:

[http://localhost:8080/%3Cscript%3Ealert(%22Impossible!%22)%3C%2Fscript%3E](http://localhost:8080/%3Cscript%3Ealert(%22Impossible!%22)%3C%2Fscript%3E)

If you are using the playground, change the host and port accordingly.

This URL will cause our Web app to display an alert box, which we, as the
developers, did not intend!

![XSS example](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/xss.png)

Despite all the URL-escapes, you may be able to see that the URL contains a
complete `<script>` tag that runs a potentially arbitrary script. Our app
happily pastes that script tag into HTML, causing the script to be executed by
our clients!

If you change the substitution back to `<%s param %>`, and visit that same URL,
you will see that the app safely formats the script tag as text:

![XSS prevented](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/no-xss.png)

<br>

In general, if you are not using the templater, you should pass any text that
will be included in HTML through
[`Dream.html_escape`](https://aantron.github.io/dream/#val-html_escape), unless
you can guarantee that it does not contain the characters `<`, `>`, `&`, `"`,
or `'`. Also, always use quoted attribute values &mdash; the rules for escaping
unquoted attributes are much more invasive.

Likewise, escaping inline scripts and CSS is also
[more complicated](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-3-javascript-encode-before-inserting-untrusted-data-into-javascript-data-values),
and not supported by Dream.

<!-- TODO Link out to more template examples. -->
<!-- TODO Recommend against generating <script>, CSS, etc. -->

<br>
<br>

**Next steps:**

- [**`8-debug`**](../8-debug#files) shows how to turn on debug responses, and
  get more info about errors.
- [**`9-error`**](../9-error#files) sets up a central error template for all
  errors.
- [**`r-template`**](../r-template#files) is a Reason syntax version of this
  example.

<br>

**See also:**

- [**`w-template-files`**](../w-template-files) moves the template into a
  separate `.eml.html` to avoid problems with editor support.
- [**`w-tyxml`**](../w-tyxml#files) shows how to use
  [TyXML](https://github.com/ocsigen/tyxml), a different templater that uses
  OCaml's type system to prevent emitting many kinds of invalid HTML.
- [**`r-tyxml`**](../r-tyxml#files) if you are using Reason. You can use TyXML
  with JSX syntax server-side!
- [**`w-template-stream`**](../w-template-stream#files) streams templates to
  responses, instead of building up complete response strings.

<br>

[Up to the tutorial index](../#readme)

<!-- TODO OWASP link; injection general link. -->
<!-- TODO Link to template syntax reference. -->
