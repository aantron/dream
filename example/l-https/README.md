# `l-https`

<br>

Enabling HTTPS in Dream is very easy: just pass `~tls:true` to
[`Dream.run`](https://aantron.github.io/dream/#val-run):

```ocaml
let () =
  Dream.run ~tls:true
  @@ Dream.logger
  @@ fun _ -> Dream.html "Good morning, world!"
```

<pre><code><b>$ cd example/l-https</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

However, when you visit [https://localhost:8080](https://localhost:8080), you
will have to click through a bunch of certificate errors. That's because, by
default, Dream uses a compiled-in
[localhost certificate](https://github.com/aantron/dream/tree/master/src/certificate),
which is suitable only for development. The certificate is technically valid,
but it is self-signed, and the browser rightly recognizes it as dubious.

For production, be sure to obtain a real certificate, for example, from
[Let's Encrypt](https://letsencrypt.org/). Pass the certificate to
[`Dream.run`](https://aantron.github.io/dream/#val-run) with `~certificate_file`
and `~key_file`.

<br>

Enabling HTTPS also enables upgrading of connections to HTTP/2, if the client
requests it. Whether HTTP/1.1 or HTTP/2 was used is completely transparent to
the Web app, though it can examine the protocol version by calling
[`Dream.version`](https://aantron.github.io/dream/#val-version) on any given
request.

<br>

**That's all for the tutorial!**

<br>

[Up to the tutorial index](../#readme)

