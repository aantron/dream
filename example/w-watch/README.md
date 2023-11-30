# `w-watch`

<br>

This example introduces dune's watch mode `exec --watch` to recompile
and run your server when you make changes.

<pre><code><b>$ cd example/w-watch</b>
<b>$ opam install --deps-only --yes .</b>
<b>$ dune exec --watch ./hello.exe</b></code></pre>

Note that this requires Dune 3.7.0 or higher.

<br>

**See also:**

- [**`w-live-reload`**](../w-live-reload#files) adds live reloading, so that
  browsers reload when the server is restarted.
- [**`w-esy`**](../w-esy#files) discusses [esy](https://esy.sh/) packaging.

<br>

[Up to the example index](../#examples)
