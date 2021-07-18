# `w-flash`

<br>

*Flash messages* are created during one request, put into cookies, and then
read by the app during the next request. They are typically used to display some
feedback from a form across a redirect.

This example does just that: it starts with two templates. The first is an
absolutely primitive form with just one field:

```ocaml
let form request =
  <html>
  <body>
    <%s! Dream.form_tag ~action:"/" request %>
      <input name="text" autofocus>
    </form>
  </body>
  </html>
```

The second template displays any flash messages, printing their category and
their text content:

```ocaml
let result request =
  <html>
  <body>

%   Dream.flash request |> List.iter (fun (category, text) ->
      <p><%s category %>: <%s text %></p><% ); %>

  </body>
  </html>
```

The app just displays the form. The text that is entered into the form by the
user is placed into a flash message using
[`Dream.put_flash`](https://aantron.github.io/dream/#val-put_flash). The app
then tells the client to redirect to `/result`. The handler for `/result` calls
the `result` template, which retrieves the flash message using
[`Dream.flash`](https://aantron.github.io/dream/#val-put_flash) and displays it.
We need to include
[`Dream.flash_messages`](https://aantron.github.io/dream/#val-flash_messages) in
our middleware stack, because that is the piece that actually puts the messages
into cookies and reads them back out:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash_messages
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["text", text] ->
          let () = Dream.put_flash "Info" text request in
          Dream.redirect request "/result"
        | _ ->
          Dream.redirect request "/");

    Dream.get "/result"
      (fun request ->
        Dream.html (result request));

  ]
  @@ Dream.not_found
```

<pre><code><b>$ cd example/w-flash</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

After starting the server, visit [http://localhost:8080](http://localhost:8080)
[[playground](http://dream.as/w-flash)] to start this little interaction!

<br>

The total size of all flash messages attached to a request has a soft limit of
about 3072 bytes. This is because cookies are generally limited to 4096 bytes,
and Dream ends up encrypting flash messages and encoding them in base64, which
blows up their original size by 4/3.

<br>

**See also:**

- [**`c-cookie`**](../c-cookie#files) shows cookie handling, the mechanism that
  flash messages are implemented over.

<br>

[Up to the example index](../#examples)
