# `r-html_of_jsx`

<br>

[html_of_jsx](https://github.com/davesnx/html_of_jsx/) can be used together with Reason's built-in JSX syntax for generating HTML on the server:

```reason
let greet = (~who, ()) =>
  <html>
    <head><title>"Home"</title></head>
    <body>
      <h1>{Jsx.txt("Good morning, " ++ who ++ "!")}</h1>
    </body>
  </html>;

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router([

    Dream.get("/",
      (_ => Dream.html(Jsx.render(<greet ~who="world" />))))),

  ]);
```

<pre><code><b>$ cd example/r-tyxml</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

To get this, we depend on package `html_of_jsx` in
[`esy.json`](https://github.com/aantron/dream/blob/master/example/r-html_of_jsx/esy.json):

<pre><code>{
  "dependencies": {
    "@opam/dream": "1.0.0~alpha4",
    "@opam/dune": "^2.0",
    "@opam/reason": "^3.8.0",
    <b>"@opam/html_of_jsx": "*",</b>
    "ocaml": "4.14.x"
  },
  "scripts": {
    "start": "dune exec --root . ./html_of_jsx.exe"
  }
}
</code></pre>

and add `html_of_jsx.ppx` to our preprocessor list in
[`dune`](https://github.com/aantron/dream/blob/master/example/r-html_of_jsx/dune):

<pre><code>(executable
 (name html_of_jsx)
 (libraries dream html_of_jsx)
 <b>(preprocess (pps lwt_ppx html_of_jsx.ppx)))</b>
</code></pre>

<br>

**See also:**

- [**`html_of_jsx`](https://github.com/davesnx/html_of_jsx/)

<br>

[Up to the example index](../#reason)
