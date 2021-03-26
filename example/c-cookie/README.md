# `c-cookie`

<br>

Let's set our own cookie:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ fun request ->
    match Dream.cookie "ui.language" request with
    | Some value ->
      Printf.ksprintf
        Dream.respond "Your preferred language is %s!" (Dream.html_escape value)

    | None ->
      Dream.response "Set language preference; come again!"
      |> Dream.add_set_cookie "ui.language" "ut-OP" request
      |> Lwt.return
```

<pre><code><b>$ dune exec --root . ./cookie.exe</b></code></pre>

<br>

The first time you access this app, it sets up a language preference, `ut-OP`.
This string is sent to the client in a cookie. On the next request, the client
sends it back. The app retrieves and displays it.

<br>

The `Dream.add_set_cookie` function is a little odd &mdash; even though it
transforms a response (by adding a `Set-Cookie:` header), it also takes a
*request* as an argument. That's because it access certain fields of the
request to set some fairly aggressive security defaults:

<!-- TODO Cite the bis RFC -->

- cookie encryption, for which it accesses the encryption key,
- whether the request likely came through an HTTPS connection, to set the
  `Secure` attribute.
- the site prefix, to set the path (almost always `/`).
- a combination of all of the above to try to set either `__Host-` or
  `__Secure-` prefixes.

All of these automatic choices can be overridden with the optional parameters
of `Dream.add_set_cookie`.

You can ignore all of this for basic usage &mdash; the cookie getter,
`Dream.cookie` “knows” how to parse such cookies, including automatic stripping
of prefixes and decryption of the value.

The only thing to note is that if you would like the cookie to be readable for
the client, you should use `~encrypt:false`. In the opposite direction, if you'd
like to stick with an encrypted cookie, be sure to eventually add `~secret` to
`Dream.run`, so that future server process can decrypt cookies &mdash; by
default, Dream generates a random key on each start.

<!-- TODO Actually round-trip cookies. -->
<!-- TODO Encoding -->
<!-- TODO Show the cookie in the browser; link to version with HTTPS. -->

<br>

## Security

- TODO Key wear-out.

<br>

**Next steps:**

- [**`d-form`**](../d-form/#files) builds secure forms on top of sessions, and
  introduces automatic handling of CSRF tokens.
- [**`e-json`**](../e-json/#files) sends and receives JSON instead!

<br>

[Up to the tutorial index](../#readme)
