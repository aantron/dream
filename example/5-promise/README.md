# `a-promise`

<br>

In this example, we write a simple version of the logger we've been using since
example [**`2-middleware`**](../2-middleware/#files), and use our custom logger
instead! We have to use Lwt, the promise library, because we need to *await* the
response form the wrapped inner handler, and *catch* if it rejects:

<!-- TODO Hyperlink. -->

```ocaml
let my_logger inner_handler request =
  Dream.log "%s %s"
    (Dream.method_to_string (Dream.method_ request))
    (Dream.target request);

  try%lwt
    let%lwt response = inner_handler request in

    let status = Dream.status response in
    Dream.log "%i %s"
      (Dream.status_to_int status)
      (Dream.status_to_string status);

    Lwt.return response

  with exn ->
    Dream.error (fun log -> log "%s" (Printexc.to_string exn));
    raise exn

let () =
  Dream.run
  @@ my_logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The web app failed!"));

  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./promise.exe</b></code></pre>

<br>

Visiting various paths with this app gives a log like this:

```
26.03.21 22:21:16.171                       Running on http://localhost:8080
26.03.21 22:21:16.171                       Press ENTER to stop
26.03.21 22:21:28.061                       REQ 1 GET /
26.03.21 22:21:28.061                       REQ 1 200 OK
26.03.21 22:21:36.898                       REQ 2 GET /random
26.03.21 22:21:36.898                       REQ 2 404 Not Found
26.03.21 22:21:39.332                       REQ 3 GET /fail
26.03.21 22:21:39.332                 ERROR REQ 3 (Failure "The web app failed!")
26.03.21 22:21:39.332      dream.http ERROR (Failure "The web app failed!")
```

See the previous example, [**`9-log`**](../9-log/#files), for more information
about logging.

<br>

As you can see, the core constructs of Lwt are:

- `let%lwt` to await the result of a promise.
- `try%lwt` to catch both exceptions and rejections. Lwt promises can only be
  rejected with exceptions, of OCaml type `exn`.
- `Lwt.return` to resolve a promise.

Besides these, Lwt has a lot of convenience functions, as well as an asychronous
I/O library.

<!-- TODO Link to read_file and write_file helpers. -->
<!-- TODO Link to Lwt_unix, Lwt_io, Lwt. -->

<br>

To use `let%lwt`, we need to modify our `dune` file slightly:

<pre><code>(executable
 (name promise)
 (libraries dream)
 <b>(preprocess (pps lwt_ppx)))</b>
</code></pre>

There are other ways to write *await* and *catch* in Lwt that don't require
`lwt_ppx`, but `lwt_ppx` is the best for preserving nice stack traces.

<!-- TODO Link to other ways. -->

<br>

**Next steps:**

- [**`b-session`**](../b-session/#files) introduces *session management* for
  associating state with clients.
- [**`c-cookie`**](../c-cookie/#files) shows *cookie handling* in Dream.

<br>

[Up to the tutorial index](../#readme)
