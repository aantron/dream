# `w-fullstack-jsoo`

<br>

This example shares a toy function between client and server using
[js_of_ocaml](https://ocsigen.org/js_of_ocaml/latest/manual/overview). The
function is in
[common/common.ml](https://github.com/aantron/dream/blob/master/example/w-fullstack-jsoo/common/common.ml).

```ocaml
let greet = function
  | `Server -> "Hello..."
  | `Client -> "...world!"
```

The first part of the message is printed by the server, in
[server/server.eml.ml](https://github.com/aantron/dream/blob/master/example/w-fullstack-jsoo/server/server.eml.ml):

```ocaml
let home =
  <html>
    <body id="body">
      <p><%s Common.greet `Server %></p>
      <script src="/static/client.js"></script>
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html home);

    Dream.get "/static/**"
      (Dream.static "./static");

  ]
```

The rest is printed by the client, in
[client/client.ml](https://github.com/aantron/dream/blob/master/example/w-fullstack-jsoo/client/client.ml):

```ocaml
open Js_of_ocaml

let () =
  let body = Dom_html.getElementById_exn "body" in
  let p = Dom_html.(createP document) in
  p##.innerHTML := Js.string (Common.greet `Client);
  Dom.appendChild body p
```

To run the example, do

<pre><code><b>cd example/w-fullstack-jsoo</b>
<b>dune build --root . client/client.bc.js
mkdir -p static
cp _build/default/client/client.bc.js static/client.js
dune exec --root . server/server.exe
</b></code></pre>

You can also trigger it all with esy with

<pre><code><b>$ cd example/w-fullstack-jsoo</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Then visit [http://localhost:8080](http://localhost:8080), and you will see...

![Full-stack greeting](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/fullstack.png)

<br>

**See also:**

- [**`w-one-binary`**](../w-one-binary#files) for bundling assets into a
  self-contained binary.

<br>

[Up to the example index](../#full-stack)
