# `w-query`

<br>

This very simple example accesses a value in the query string with
[`Dream.query`](https://aantron.github.io/dream/#val-query):

```ocaml
let () =
  Dream.run (fun request ->
    match Dream.query request "echo" with
    | None ->
      Dream.html "Use ?echo=foo to give a message to echo!"
    | Some message ->
      Dream.html (Dream.html_escape message))
```

<pre><code><b>$ cd example/w-query</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Visit [http://localhost:8080?echo=foo](http://localhost:8080?echo=foo)
[[playground](http://dream.as/w-query?echo=foo)] and you will see `foo`
printed! Since we are inserting untrusted client-sent data into an HTML
response, we have to escape it with
[`Dream.html_escape`](https://aantron.github.io/dream/#val-html_escape). See
*Security* in example [**`7-template`**](../7-template#security) for a
discussion. Perhaps you can even launch an XSS attack against an unsafe version
of this example!

<br>

[Up to the example index](../#examples)
