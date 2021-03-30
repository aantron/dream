# `e-json`

<br>

TODO

<!-- Adjust once the templater vertical whitespace bug is fixed again. -->

```ocaml
let show_form ?message request =
  <html>
    <body>
%     begin match message with
%     | None -> ()
%     | Some message ->
        <p>You entered: <b><%s message %>!</b></p>
%     end;
      <%s! Dream.Tag.form ~action:"/" request %>
        <input name="message" autofocus>
      </form>
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sessions_in_memory
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.respond (show_form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["message", message] ->
          Dream.respond (show_form ~message request)
        | _ ->
          Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./promise.exe</b></code></pre>

<br>

TODO

<br>

**Next steps:**

- [**`b-session`**](../b-session/#files) introduces *session management* for
  associating state with clients.
- [**`c-cookie`**](../c-cookie/#files) shows *cookie handling* in Dream.

<br>

[Up to the tutorial index](../#readme)

