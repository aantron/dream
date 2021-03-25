# `5-echo`

<br>

This example just echoes the bodies of `POST /echo` requests:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/echo" (fun request ->
      Lwt.map Dream.response (Dream.body request));
  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./echo.exe</b></code></pre>

<br>

You can test it with curl:

<pre><code><b>$ curl http://localhost:8080/echo --data foo</b>
foo
</code></pre>

Or try [HTTPie](https://httpie.io/):

<pre><code><b>$ echo -n foo | http POST :8080/echo</b>
HTTP/1.1 200 OK
Content-Length: 3

foo
</code></pre>

<br>

<!-- TODO hyperlink -->

The code uses
[`Lwt.map`](https://github.com/ocsigen/lwt/blob/c5f895e35a38df2d06f19fd23bf553129b9e95b3/src/core/lwt.mli#L1279). That's
because `Dream.body` returns the body string inside a promise, and we want to
transform that string promise into a response promise with `Dream.response`.
This is just a touch of Lwt, because we need it here! Example
[**`a-promise`**](../a-promise/#files) introduces Lwt promises fully.

<br>

We usually want to do something more interesting with the request body than just
echo it, and there are several examples for that!

- [**`d-form`**](../d-form/#files) parses request bodies as forms.
- [**`e-json`**](../e-json/#files) parses them as JSON.
- [**`g-upload`**](../g-upload/#files) receives file upload forms.
- [**`i-graphql`**](../i-graphql/#files) receives GraphQL queries!
- [**`j-streaming`**](../j-streaming/#files) streams huge bodies.

We delay these examples a bit, so we can squeeze in a couple security topics
first. These examples do take client input, after all! So, it's better to
present them the right way.

<br>

**Next steps:**

- [**`6-template`**](../6-template/#files) renders responses from templates and
  guards against injection attacks (XSS).
- [**`7-debug`**](../7-debug/#files) renders error information in responses.

<br>

[Up to the tutorial index](../#readme)
