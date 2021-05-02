# `r-hello`

<br>

This example shows the simplest Dream program one could write:

```reason
let () =
  Dream.run(_ =>
    Dream.html("Good morning, reasonable world!"));
```

<pre><code><b>$ cd example/r-hello</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b>
08.04.21 13:55:56.552                       Running at http://localhost:8080
08.04.21 13:55:56.553                       Type Ctrl+C to stop
</code></pre>

<br>

After starting it, visit [http://localhost:8080](http://localhost:8080), or use
the [playground](http://dream.as/r-hello), and it will respond with its friendly
greeting!

<br>

Note that we had to make an addition to
[`esy.json`](https://github.com/aantron/dream/blob/master/example/r-hello/esy.json):

<pre>"dependencies": {
  <b>"@opam/reason": "^3.0.0"</b>
}
</pre>

<br>
<br>

**See also:**

- [**`r-template`**](../r-template#files) shows templates with Reason syntax.
- [**`2-middleware`**](../2-middleware) introduces the *logger*, the most
  commonly used Dream middleware. The example is in OCaml syntax.

<br>

[Up to the example index](../#reason)
