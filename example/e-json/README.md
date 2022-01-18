# `e-json`

<br>

<!-- TODO Add ppx_deriving example. -->

In this example, we use
[ppx_yojson_conv](https://github.com/janestreet/ppx_yojson_conv) to generate a
converter between JSON and an OCaml data type. We then create a little server
that listens for JSON of the right shape, and echoes back its `message` field:

```ocaml
type message_object = {
  message : string;
} [@@deriving yojson]

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referrer_check
  @@ Dream.router [

    Dream.post "/"
      (fun request ->
        let%lwt body = Dream.body request in

        let message_object =
          body
          |> Yojson.Safe.from_string
          |> message_object_of_yojson
        in

        `String message_object.message
        |> Yojson.Safe.to_string
        |> Dream.json);

  ]
  @@ Dream.not_found
```

To get this working, we have to add `ppx_yojson_conv` to our
[`dune`](https://github.com/aantron/dream/blob/master/example/e-json/dune) file:

<pre><code>(executable
 (name json)
 (libraries dream)
 <b>(preprocess (pps ppx_yojson_conv)))</b>
</code></pre>

and to
[`esy.json`](https://github.com/aantron/dream/blob/master/example/e-json/esy.json):

<pre><code>{
"dependencies": {
  "@opam/dream": "aantron/dream:dream.opam",
  "@opam/dune": "^2.0",
  <b>"@opam/ppx_yojson_conv": "*",</b>
  "ocaml": "4.12.x"
}
</code></pre>

The build commands, as always, are:

<pre><code><b>$ cd example/e-json</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

You can try this example in the [playground](http://dream.as/e-json).

<br>

This example expects JSON of the form `{"message": "some-message"}`. Let's test
it with both curl and [HTTPie](https://httpie.io/):

<pre><b>$ curl http://localhost:8080 \
    -H "Origin: http://localhost:8080" \
    -H "Host: localhost:8080" \
    -H "Content-Type: application/json" \
    --data '{"message": "foo"}'</b>

"foo"

<b>$ echo '{"message": "foo"}' | \
    http POST :8080 Origin:http://localhost:8080 Host:localhost:8080</b>

HTTP/1.1 200 OK
Content-Length: 5
Content-Type: application/json

"foo"
</pre>

<br>

## Security

[`Dream.origin_referrer_check`](https://aantron.github.io/dream/#val-origin_referrer_check)
implements the
[OWASP Verifying Origin With Standard Headers](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#verifying-origin-with-standard-headers)
CSRF protection technique. It doesn't protect `GET` requests, so they shouldn't
do mutations. It also isn't good enough for cross-origin usage in its current
form. But it is enough to do AJAX in small and medium Web apps without the need
for [generating tokens](https://aantron.github.io/dream/#csrf-tokens).

This technique relies on that the browser will send matching `Origin:` (or
`Referer:`) and `Host:` headers to the Web app for a genuine request, while,
for a cross-site request, `Origin:` and `Host:` will not match &mdash;
`Origin:` will be the other site or `null`. Try varying the headers in the
`curl` and `http` commands to see the check in action, rejecting your nefarious
requests!

<br>
<br>

**Next steps:**

- [**`f-static`**](../f-static#files) serves static files from the local
  file system.
- [**`g-upload`**](../g-upload#files) receives files from an upload form.

<br>

[Up to the tutorial index](../#readme)

