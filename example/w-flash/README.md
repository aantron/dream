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
    <form method="POST" action="/">
      <%s! Dream.csrf_tag request %>
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

%   Dream.flash_messages request |> List.iter (fun (category, text) ->
      <p><%s category %>: <%s text %></p><% ); %>

  </body>
  </html>
```

The app just displays the form. The text that is entered into the form by the
user is placed into a flash message using
[`Dream.add_flash_message`](https://aantron.github.io/dream/#val-add_flash_message).
The app
then tells the client to redirect to `/result`. The handler for `/result` calls
the `result` template, which retrieves the flash message using
[`Dream.flash_messages`](https://aantron.github.io/dream/#val-flash_messages)
and displays it. We need to include
[`Dream.flash`](https://aantron.github.io/dream/#val-flash) in our middleware
stack, because that is the piece that actually puts the messages into cookies
and reads them back out:

```ocaml
let () =
  Dream.set_log_level "dream.flash" `Debug;
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["text", text] ->
          let () = Dream.add_flash_message request "Info" text in
          Dream.redirect request "/result"
        | _ ->
          Dream.redirect request "/");

    Dream.get "/result"
      (fun request ->
        Dream.html (result request));

  ]
```

The example configures a custom log level for flash messages using
`Dream.set_log_level`. Setting this to `` `Debug`` means the server logs
will display a log point summarizing the flash messages on every
request, like this:

```
10.11.21 01:48:21.629       dream.log  INFO REQ 3 GET /result ::1:39808 Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0
10.11.21 01:48:21.629     dream.flash DEBUG REQ 3 Flash messages: Info: Some Message
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
