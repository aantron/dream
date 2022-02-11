# `w-one-binary`

This example bakes static assets into the server binary file. The whole web app
is contained inside just `one_binary.exe`!

<br>

First, we make the
[`dune`](https://github.com/aantron/dream/blob/master/example/w-one-binary/dune)
file call [crunch](https://github.com/mirage/ocaml-crunch) to turn the
[`assets/`](https://github.com/aantron/dream/tree/master/example/w-one-binary/assets)
directory into a file `assets.ml`:

<pre><code><b>(rule
 (target assets.ml)
 (deps (source_tree assets))
 (action (with-stdout-to %{null}
  (run ocaml-crunch -m plain assets -o %{target}))))
</b></code></pre>

crunch comes from the opam repository, so we also add it in
[`esy.json`](https://github.com/aantron/dream/blob/master/example/w-one-binary/esy.json):

<pre><code>"dependencies": {
  <b>"@opam/crunch": "*"</b>
}
</code></pre>

<br>

The generated `assets.ml` has a signature like this:

```ocaml
val Assets.file_list : string list
(* ["README.md"; "camel.jpeg"] *)

val Assets.read : string -> string option
(* Assets.read "camel.jpeg" and Assets.read "/camel.jpeg" both work. *)
```

<br>

After that, we just need to tell
[`Dream.static`](https://aantron.github.io/dream/#val-static) to load files from
module `Assets`, rather than from the file system. We do this by passing it the
optional `~loader` argument:

```ocaml
let loader _root path _request =
  match Assets.read path with
  | None -> Dream.empty `Not_Found
  | Some asset -> Dream.respond asset

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/assets/**" (Dream.static ~loader "")
  ]
```

[`Dream.static`](https://aantron.github.io/dream/#val-static) will take care of
adding a `Content-Type` to each file, based on its extension. You can override
it by setting `Content-Type` yourself when calling
[`Dream.respond`](https://aantron.github.io/dream/#val-respond), or using
[`Dream.add_header`](https://aantron.github.io/dream/#headers).

<br>

To build the whole setup, just do

<pre><code><b>$ cd example/w-one-binary</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

You can now visit
[http://localhost:8080/assets/camel.jpeg](http://localhost:8080/assets/camel.jpeg)
for a picture of a nice camel:

![Camel](https://raw.githubusercontent.com/aantron/dream/master/example/w-one-binary/assets/camel.jpeg)

[http://localhost:8080/assets/README.md](http://localhost:8080/assets/README.md)
gives the source link and license information for the image.

<br>

Copy the binary out for deployment with

<pre><code><b>$ npx esy cp '#{self.target_dir}/default/one_binary.exe' .
</b></code></pre>

It will continue to serve the camel no matter where it is moved to! The
`assets/` directory from this example doesn't have to be copied along with it.

<br>

If you'd like to inspect the generated `assets.ml` yourself, run

<pre><code><b>$ npx esy less '#{self.target_dir}/default/assets.ml'
</b></code></pre>

To add more files, just add them to the `assets/` directory and re-run
`npx esy run`. Dune and crunch will pick them up automatically.

<br>

**See also:**

- [**`w-esy`**](../w-esy#files) for details on packaging with esy.
- [**`w-fswatch`**](../w-fswatch#files) for a primitive watcher, which can be
  extended to watch `assets/`.
- [**`f-static`**](../f-static#files) shows the basics of
  [`Dream.static`](https://aantron.github.io/dream/#val-static).

<br>

[Up to the example index](../#examples)
