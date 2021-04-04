# `7-template`

<br>

Dream [*templates*](https://aantron.github.io/dream/#templates) allow
interleaving OCaml and HTML in a pretty straightforward way, and help with
[XSS prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html).
After looking at the correct example, we will
[weaken and then exploit it](#security).

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
        |> Dream.respond);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./template.exe</b></code></pre>

<br>

This requires a bit more setup in our `dune` file to run the template
preprocessor:

<pre><code>(executable
 (name template)
 (libraries dream)
 (preprocess (pps lwt_ppx)))

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
this tiny web app! First, go to
[`template.eml.ml`](https://github.com/aantron/dream/blob/master/example/7-template/template.eml.ml#L4),
change the substitution to `<%s! param %>`, and restart the app. Then, go to
this URL:

[http://localhost:8080/%3Cscript%3Ealert(%22foo%22)%3C%2Fscript%3E](http://localhost:8080/%3Cscript%3Ealert(%22foo%22)%3C%2Fscript%3E)

This cryptic and highly questionable URL will cause our web app to display an
alert box, which we, as the developers, did not intend!



Despite all the URL-escapes, you may be able to see that the URL contains a
complete `<script>` tag that runs a potentially arbitrary script. Our app
happily pastes that script tag into HTML, causing the script to be executed by
our clients!

If you change the substitution back to `<%s param %>`, and visit that same URL,
you will see that the app safely formats the script tag as text.

<br>

In general, if you are not using the templater, you should pass any text that
will be included in HTML through `Dream.html_escape`, unless you can guarantee
that it does not contain the characters `<`, `>`, `&`, `"`, or `'`. Also,
always use quoted attribute values &mdash; the rules for escaping unquoted
attributes are much more invasive.

<!-- TODO Link out to more template examples. -->
<!-- TODO Recommend against generating <script>, CSS, etc. -->

<br>
<br>

**Next steps:**

- [**`8-debug`**](../8-debug/#files) shows how to turn on debug responses, and
  get more info about errors.
- [**`9-error`**](../9-error/#files) sets up a central error template for all
  errors.

<br>

[Up to the tutorial index](../#readme)

<!-- TODO OWASP link; injection general link. -->
<!-- TODO Link to template syntax reference. -->
