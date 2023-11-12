# `d-form`

<br>

With the session middleware from example [**`b-session`**](../b-session#files),
we can build a [secure form](https://aantron.github.io/dream/#forms):

```ocaml
let show_form ?message request =
  <html>
  <body>

%   begin match message with
%   | None -> ()
%   | Some message ->
      <p>You entered: <b><%s message %>!</b></p>
%   end;

    <form method="POST" action="/">
      <%s! Dream.csrf_tag request %>
      <input name="message" autofocus>
    </form>

  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (show_form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["message", message] ->
          Dream.html (show_form ~message request)
        | _ ->
          Dream.empty `Bad_Request);

  ]
```

<pre><code><b>$ cd example/d-form</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/d-form).

<br>

The template adds a CSRF token to the form using
[`Dream.csrf_tag`](https://aantron.github.io/dream/#val-csrf_tag). Its output
looks something like this:

```html
<form method="POST" action="/">
  <input name="dream.csrf" type="hidden" value="j8vjZ6...">
  <input name="message" autofocus>
</form>
```

That generated, hidden `dream.csrf` field helps to [prevent CSRF
attacks](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html).
It should be the [first
field](https://portswigger.net/web-security/csrf/tokens#how-should-csrf-tokens-be-transmitted)
in your form.

When the form is submitted and parsed using
[`Dream.form`](https://aantron.github.io/dream/#val-form), `Dream.form` expects
to find the `dream.csrf` field, and checks it. If there is anything wrong with
the CSRF token, [`Dream.form`](https://aantron.github.io/dream/#val-form) will
return a [value other than
`` `Ok _``](https://aantron.github.io/dream/#type-form_result).

<br>

The form fields carried inside `` `Ok _`` are returned in sorted order, so you
can reliably pattern-match on them.

The bad token results, like `` `Expired (_, _)``, also carry the form fields.
You can add handling for them to recover. For example, if you receive a form
with an expired token, you may want to resend it with some of the fields pre-
filled to received values, so that the user can try again quickly.

However, do not send back any sensitive data, because *any* result other than
`` `Ok _`` *might* indicate an attack in progress. That said, `` `Expired _``
and `` `Wrong_session _`` do often occur during normal user activity. The other
constructors typically correspond to bugs or attacks, only.

<br>

This example replied to the form POST directly with HTML. In most cases, it is
better to use [`Dream.redirect`](https://aantron.github.io/dream/#val-redirect)
instead, to forward the browser to another page that will display the outcome.
Using a redirection prevents form resubmission on refresh. This is especially
important on login forms and other sensitive pages.

However, this server is so simple that it doesn't store the data anywhere, and
the data is not sensitive, so we took a shortcut. See
[**`h-sql`**](../h-sql#files) for an example with a proper redirection.

<br>

**Next steps:**

- [**`e-json`**](../e-json#files) receives and sends JSON.
- [**`f-static`**](../f-static#files) serves static files from a local
  directory.

<br>

[Up to the tutorial index](../#readme)

