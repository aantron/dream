# `r-fullstack-melange`

<br>

This example shares a toy function between client and server using
[Melange](https://github.com/melange-re/melange). The function is in
[common/common.re](https://github.com/aantron/dream/blob/master/example/r-fullstack-melange/common/common.re):

```reason
let greet = fun
  | `Server => "Hello..."
  | `Client => "...world!";
```

The server, in
[server/server.eml.re](https://github.com/aantron/dream/blob/master/example/r-fullstack-melange/server/server.eml.re),
prints the first part of the message:

```reason
let home = {
  <html>
    <body>
      <p><%s Common.greet(`Server) %></p>
      <script src="/static/client.js"></script>
    </body>
  </html>
};

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(home))),

    Dream.get("/static/**",
      Dream.static("./static")),

  ]);
```

...and the client, in
[client/client.re](https://github.com/aantron/dream/blob/master/example/r-fullstack-melange/client/client.re),
completes it!

```reason
open Webapi.Dom;

let () = {
  let body = document |> Document.querySelector("body");

  switch (body) {
  | None => ()
  | Some(body) =>

    let text = Common.greet(`Client);

    let p = document |> Document.createElement("p");
    p->Element.setInnerText(text);
    body |> Element.appendChild(p);
  }
};
```

To run, do

<pre><code><b>npm install
npm start
</b></code></pre>

Then visit [http://localhost:8080](http://localhost:8080), and you will see...

![Full-stack greeting](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/fullstack.png)

<br>

As a footnote, it is also possible to write both the server and client in this
example in OCaml syntax.

<br>

**See also:**

- [**`w-esy`**](../w-esy#files) details the server's [esy](https://esy.sh/)
  packaging.
- [**`w-fswatch`**](../w-fswatch#files) sets up a primitive development watcher.
- [**`w-one-binary`**](../w-one-binary#files) bundles assets into a
  self-contained binary.
- [**`7-template`**](../7-template#files) discusses the templater, including
  security. The example is in OCaml syntax.

<br>

[Up to the example index](../#full-stack)
