# `c-cookie`

<br>

Let's [set our own cookie](https://aantron.github.io/dream/#cookies):

```ocaml
let () =
  Dream.run
  @@ Dream.set_secret "foo"
  @@ Dream.logger
  @@ fun request ->

    match Dream.cookie request "ui.language" with
    | Some value ->
      Printf.ksprintf
        Dream.html "Your preferred language is %s!" (Dream.html_escape value)

    | None ->
      let response = Dream.response "Set language preference; come again!" in
      Dream.add_header response "Content-Type" Dream.text_html;
      Dream.set_cookie response request "ui.language" "ut-OP";
      Lwt.return response
```

<pre><code><b>$ cd example/c-cookie</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The first time you access this app [[playground](http://dream.as/c-cookie)], it
sets up a language preference, `ut-OP`. This string is sent to the client in a
`ui.language` cookie. On the next request, the client sends it back. The app
retrieves and displays it.

<br>

The [`Dream.set_cookie`](https://aantron.github.io/dream/#val-set_cookie)
function is a little odd &mdash; even though it transforms a response (by
adding a `Set-Cookie:` header), it also takes a *request* as an argument.
That's because it access certain fields of the request to set some fairly
aggressive security defaults:

- Cookie encryption, for which it accesses the encryption key. This is why we
  used the
  [`Dream.set_secret`](https://aantron.github.io/dream/#val-set_secret)
  middleware.
- Whether the request likely came through an HTTPS connection, to set the
  [`Secure`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#restrict_access_to_cookies)
  attribute.
- The site prefix, to set the
  [path](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Path_attribute)
  (almost always `/`).
- A combination of all of the above to try to set either [`__Host-` or
  `__Secure-`
  prefixes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Cookie_prefixes).

[`Dream.set_cookie`](https://aantron.github.io/dream/#val-set_cookie) also sets
other security defaults, but doesn't need to check the request for them.

All of these automatic choices can be overridden with the optional parameters
of [`Dream.set_cookie`](https://aantron.github.io/dream/#val-set_cookie).

<br>

You can ignore all of this for basic usage &mdash; the cookie getter,
[`Dream.cookie`](https://aantron.github.io/dream/#val-cookie) “knows” how to
parse such cookies, including automatic stripping of prefixes and decryption of
the value.

So, if you use
[`Dream.set_cookie`](https://aantron.github.io/dream/#val-set_cookie) and
[`Dream.cookie`](https://aantron.github.io/dream/#val-cookie) together, you get
the most secure settings automatically “for free.”

<br>

You may wish to not encrypt the cookie value, because...

- it does not contain sensitive data,
- it needs to be readable by the client, or
- it is already encrypted.

In that case, pass `~encrypt:false` to
[`Dream.set_cookie`](https://aantron.github.io/dream/#val-set_cookie) and
`~decrypt:false` to
[`Dream.cookie`](https://aantron.github.io/dream/#val-cookie). However, then you
need to escape the cookie value so that it does not contain `=`, `;` or
newlines, and undo the escaping after reading the value.

The easiest way to do that for general data is to use
[`Dream.to_base64url`](https://aantron.github.io/dream/#val-to_base64url) and
[`Dream.from_base64url`](https://aantron.github.io/dream/#val-from_base64url).

<br>

**Next steps:**

- [**`d-form`**](../d-form#files) builds secure forms on top of sessions, and
  introduces automatic handling of CSRF tokens.
- [**`e-json`**](../e-json#files) sends and receives JSON instead!

<br>

[Up to the tutorial index](../#readme)
