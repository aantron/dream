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
    <form method="POST" action="/" enctype="multipart/form-data">
      <%s! Dream.csrf_tag request %>
      <input name="files" type="file" multiple>
      <button>Submit!</button>
    </form>
  </body>
  </html>

let report files =
  <html>
  <body>
%   files |> List.iter begin fun (name, content) ->
%     let name =
%       match name with
%       | None -> "None"
%       | Some name -> name
%     in
      <p><%s name %>, <%i String.length content %> bytes</p>
%   end;
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
      | `Ok ["files", files] -> Dream.html (report files)
      | _ -> Dream.empty `Bad_Request);

  ]
```

<pre><code><b>$ cd example/g-upload</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The page shown after uploading looks like this
[[playground](http://dream.as/g-upload)]:

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
See example [**`d-form`**](../d-form#files). We use
[`Dream.csrf_tag`](https://aantron.github.io/dream/#val-csrf_tag) to generate
the CSRF token in the template, and pass the `enctype="multipart/form-data"`
attribute as needed for forms to upload files. The template output looks like
this:

```html
<form method="POST" action="/" enctype="multipart/form-data">
  <input name="dream.csrf" type="hidden" value="...">

  <!-- Our fields -->
  <input name="files" type="file" multiple>
  <button>Submit!</button>
</form>
```

See [OWASP File Upload Cheat
Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)
for a checklist of additional security precautions.

<br>
<br>

**Next steps:**

- [**`h-sql`**](../h-sql#files) runs SQL queries against a database.
- [**`i-graphql`**](../i-graphql#files) handles GraphQL queries and serves
  GraphiQL.

<br>

**See also:**

- [**`w-upload-stream`**](../w-upload-stream#files) shows the streaming
  interface for receiving file uploads.
- [**`w-multipart-dump`**](../w-multipart-dump#files) shows the request body
  that is interpreted by
  [`Dream.multipart`](https://aantron.github.io/dream/#val-multipart).

<br>

[Up to the tutorial index](../#readme)
