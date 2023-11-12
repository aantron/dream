# `6-echo`

<br>

This example just echoes the bodies of `POST /echo` requests, after reading
them with [`Dream.body`](https://aantron.github.io/dream/#val-body):

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.post "/echo" (fun request ->
      let%lwt body = Dream.body request in
      Dream.respond
        ~headers:["Content-Type", "application/octet-stream"]
        body);

  ]
```

<pre><code><b>$ cd example/6-echo</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

...or run it in the [playground](http://dream.as/6-echo).

<br>

You can test it with curl:

<pre><code><b>$ curl http://localhost:8080/echo --data foo</b>
foo
</code></pre>

...or try [HTTPie](https://httpie.io/):

<pre><code><b>$ echo -n foo | http POST :8080/echo</b>
HTTP/1.1 200 OK
Content-Length: 3

foo
</code></pre>

<br>

We usually want to do something more interesting with the request body than just
echo it, and there are several examples for that!

- [**`d-form`**](../d-form#files) parses request bodies as forms.
- [**`e-json`**](../e-json#files) parses bodies as JSON.
- [**`g-upload`**](../g-upload#files) receives file upload forms.
- [**`i-graphql`**](../i-graphql#files) receives GraphQL queries.
- [**`j-stream`**](../j-stream#files) streams huge bodies.

We delay these examples a bit, so we can squeeze in a couple security topics
first. These examples do take client input, after all! So, it's better to
present them the right way.

<!-- TODO Revisit this table, make sure links work. -->

<br>

**Next steps:**

- [**`7-template`**](../7-template#files) builds responses from templates and
  guards against injection attacks (XSS).
- [**`8-debug`**](../8-debug#files) renders error information in responses.

<br>

[Up to the tutorial index](../#readme)
