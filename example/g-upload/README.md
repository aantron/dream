# `g-upload`

<br>

This example shows an upload form at
[http://localhost:8080](http://localhost:8080), which allows sending multiple
files. When they are sent, the example responds with a page listing their file
sizes:

```ocaml
let home request =
  <html>
    <body>
      <%s! Dream.form_tag ~action:"/" ~enctype:`Multipart_form_data request %>
        <input name="files" type="file" multiple>
        <button>Submit!</button>
      </form>
    </body>
  </html>

let report files =
  <html>
    <body>
%     files |> List.iter begin fun (name, content) ->
        <p><%s name %>: <%i String.length content %> bytes</p>
%     end;
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/" (fun request ->
      Dream.html (home request));

    Dream.post "/" (fun request ->
      match%lwt Dream.multipart request with
      | `Ok ["files", `Files files] -> Dream.html (report files)
      | _ -> Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The page shown after uploading looks like this:

```
foo.png, 663959 bytes
bar.png, 1807 bytes
```

<br>

This example uses
[`Dream.multipart`](https://aantron.github.io/dream/#val-multipart) (named
after `Content-Type: multipart/form-data`).
[`Dream.multipart`](https://aantron.github.io/dream/#val-multipart) receives
entire files into strings. Size limits will be added in one of the early alphas.
However, this is only good for rare, small uploads, such as user avatars, or for
prototyping.

For more heavy usage, see
[`Dream.upload`](https://aantron.github.io/dream/#type-upload_event) for
streaming file uploads.

<br>

## Security

[`Dream.multipart`](https://aantron.github.io/dream/#val-multipart) behaves just
like [`Dream.form`](https://aantron.github.io/dream/#val-form) when it comes to
[CSRF protection](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html).
See example [**`d-form`**](../d-form#files). We still use
[`Dream.form_tag`](https://aantron.github.io/dream/#val-form_tag) to generate
the form in the template. The only difference is that we now pass it
``~enctype:`Multipart_form_data`` to make its output look like this:

```html
<form method="POST" action="/" enctype="multipart/form-data">
  <input name="dream.csrf" type="hidden" value="...">

  <!-- Our fields -->
  <input name="files" type="file" multiple>
  <button>Submit!</button>
</form>
```

By contrast with
[`Dream.multipart`](https://aantron.github.io/dream/#val-multipart),
[`Dream.upload`](https://aantron.github.io/dream/#val-upload) offers no
built-in CSRF protection at all at present. You can, however, still use
[`Dream.form_tag`](https://aantron.github.io/dream/#val-form_tag), and manually
call
[`Dream.verify_csrf_token`](https://aantron.github.io/dream/#val-verify_csrf_token)
when you stream a `dream.csrf` field. You'll then have to decide what to do
about files already received.

<br>
<br>

**Next steps:**

- [**`h-sql`**](../h-sql#files) runs SQL queries against a database.
- [**`i-graphql`**](../i-graphql#files) handles GraphQL queries and serves
  GraphiQL.

<br>

[Up to the tutorial index](../#readme)
