# `r-hello`

<br>

This example shows the simplest Dream program one could write:

```reason
let () =
  Dream.run(_ =>
    Dream.respond("Good morning, reasonable world!"));
```

<pre><code><b>$ dune exec --root . ./hello.exe</b>
08.04.21 13:55:56.552                       Running on http://localhost:8080
08.04.21 13:55:56.553                       Press ENTER to stop
</code></pre>

<br>

After starting it, visit [http://localhost:8080](http://localhost:8080), and it
will respond with its friendly greeting!

<br>

**See also:**

- [**`r-template`**](../r-template#files) shows templates with Reason syntax.
- [**`2-middleware`**](../2-middleware) introduces the *logger*, the most
  commonly used Dream middleware. The example is in OCaml syntax.

<br>

[Up to the example index](../#reason)
