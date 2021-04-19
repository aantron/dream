# `w-esy`

<br>

To depend on Dream using [esy](https://esy.sh/en/), put this in your
`package.json`:

```json
{
  "dependencies": {
    "@opam/dream": "aantron/dream:dream.opam",
    "@opam/dune": "^2.0",
    "ocaml": "4.12.x"
  },
  "scripts": {
    "run": "dune exec --root . ./hello.exe"
  }
}
```

<br>

You now have a variant of example [**`1-hello`**](../1-hello#files) with proper
esy metadata!

<pre><code><b>$ npx esy</b>
<b>$ npx esy run</b>
19.04.21 08:57:33.450                       Running on http://localhost:8080
19.04.21 08:57:33.450                       Press ENTER to stop
</code></pre>

If you go to [http://localhost:8080](http://localhost:8080), you will see
`Good morning, world!`, just as in [**`1-hello`**](../1-hello#files)!

<br>

We download the `esy` binary from npm and run it using the
[`npx`](https://docs.npmjs.com/cli/v7/commands/npx) command. Another option is
to install esy globally on your system with

```
npx install -g esy
```

You can then use the `esy` command without the `npx` prefix.

<br>

Many of the packages you can obtain with esy are hosted in
[opam](https://opam.ocaml.org/), the OCaml package repository. In esy, their
names are prefixed with `@opam`, like `@opam/dream`. You can search the packages
[here](https://opam.ocaml.org/packages/).

<br>

In addition to the files you see in this example, `npx esy` also generates a
directory called `esy.lock`. It's a set of lock files, similar to
`package-lock.json`. You should usually commit `esy.lock` &mdash; we left it out
of this example to keep it in sync with the Dream repo and its upstream
projects, but this deliberately gives up reproducible builds.

<br>

Once you've got the server in this example building with esy, you can develop a
JavaScript client as normal, with npm or Yarn. Simply scope this example's
`package.json`inside an `"esy"` key, and write your usual, client-side
`package.json` outside:

```json
{
  "esy": {
    "dependencies": {
      "@opam/dream": "aantron/dream:dream.opam",
      "@opam/dune": "^2.0",
      "ocaml": "4.12.x"
    },
    "scripts": {
      "run": "dune exec --root . ./hello.exe"
    }
  },

  "dependencies": {
    "client": "dependencies"
  }
}
```

npm will ignore `"esy"`, while esy will read exactly only `"esy"`! An
alternative is to rename the server-side `package.json` to `esy.json`.

You can make this even more powerful by writing the client itself in OCaml,
Reason, or ReScript &mdash; all flavors of OCaml that compile to JavaScript.
See the examples linked below. The ReScript compiler can compile all three
languages. Melange compiles OCaml and Reason.

<br>

**See also:**

- [**`w-fullstack-rescript`**](../w-fullstack-rescript#files) for full-stack
  development with ReScript.
- [**`r-fullstack-melange`**](../r-fullstack-melange#files) for full-stack
  development with Melange and Reason syntax.
- [**`w-fswatch`**](../w-fswatch#files) for a development watcher.

<br>

[Up to the example index](../#examples)
