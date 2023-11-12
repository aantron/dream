# `5-promise`

<br>

[**`4-counter`**](../4-counter#files) was limited to counting requests *before*
passing them on to the rest of the app. With the promise library
[Lwt](https://github.com/ocsigen/lwt), we can await responses, and do something
*after*. In this example, we separately count requests that were handled
successfully, and those that caused an exception:

```ocaml
let successful = ref 0
let failed = ref 0

let count_requests inner_handler request =
  try%lwt
    let%lwt response = inner_handler request in
    successful := !successful + 1;
    Lwt.return response

  with exn ->
    failed := !failed + 1;
    raise exn

let () =
  Dream.run
  @@ Dream.logger
  @@ count_requests
  @@ Dream.router [

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The Web app failed!"));

    Dream.get "/" (fun _ ->
      Dream.html (Printf.sprintf
        "%3i request(s) successful<br>%3i request(s) failed"
        !successful !failed));

  ]
```

<pre><code><b>$ cd example/5-promise</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/5-promise).

<br>

As you can see, the
[core constructs](https://ocsigen.org/lwt/latest/api/Ppx_lwt) of Lwt are:

- `let%lwt` to await the result of a promise.
- `try%lwt` to catch both exceptions and rejections. Lwt promises can only be
  rejected with exceptions, of OCaml type `exn`.
- `Lwt.return` to resolve a promise.

Besides these, Lwt has a lot of [convenience
functions](https://ocsigen.org/lwt/latest/api/Lwt), and an [asychronous
I/O library](https://ocsigen.org/lwt/latest/api/Lwt_unix).

<!-- TODO Link to read_file and write_file helpers. -->
<!-- TODO Link to Lwt_unix, Lwt_io, Lwt. -->

<br>

To use `let%lwt`, we need to modify our
[`dune`](https://github.com/aantron/dream/blob/master/example/5-promise/dune)
file a bit to include `lwt_ppx`:

<pre><code>(executable
 (name promise)
 (libraries dream)
 <b>(preprocess (pps lwt_ppx)))</b>
</code></pre>

There are other ways to write *await* and *catch* in Lwt that don't require
`lwt_ppx`, but `lwt_ppx` is presently the best for preserving nice stack traces.
For example, `let%lwt` is equivalent to...

- [`Lwt.bind`](https://github.com/ocsigen/lwt/blob/c5f895e35a38df2d06f19fd23bf553129b9e95b3/src/core/lwt.mli#L475),
  which is almost never used directly.
- [`>>=`](https://github.com/ocsigen/lwt/blob/c5f895e35a38df2d06f19fd23bf553129b9e95b3/src/core/lwt.mli#L1395)
  from module `Lwt.Infix`.
- [`let*`](https://github.com/ocsigen/lwt/blob/c5f895e35a38df2d06f19fd23bf553129b9e95b3/src/core/lwt.mli#L1511)
  from module `Lwt.Syntax`, which is showcased in Lwt's
  [README](https://github.com/ocsigen/lwt#readme).

We will stick to `let%lwt` in the examples and keep things tidy.

<br>

**Next steps:**

- [**`6-echo`**](../6-echo#files) uses Dream and Lwt to read a request body.
- [**`7-template`**](../7-template#files) shows how to interleave HTML and
  OCaml.

<br>

[Up to the tutorial index](../#readme)
