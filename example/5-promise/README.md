# `5-promise`

(note this example is now badly named, as it doesn't use any promises)

<br>

[**`4-counter`**](../4-counter#files) was limited to counting requests *before*
passing them on to the rest of the app. We can also await responses, and do
something *after*. In this example, we separately count requests that were
handled successfully, and those that caused an exception:

```ocaml
let successful = ref 0
let failed = ref 0

let count_requests inner_handler request =
  try
    let response = inner_handler request in
    successful := !successful + 1;
    response
  with exn ->
    failed := !failed + 1;
    raise exn

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
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
  @@ Dream.not_found
```

<pre><code><b>$ cd example/5-promise</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

Try it in the [playground](http://dream.as/5-promise).

<br>

As you can see, we use `try` to catch both exceptions and rejections.

<!-- TODO Link to read_file and write_file helpers. -->
<!-- TODO Link to Lwt_unix, Lwt_io, Lwt. -->

<br>

**Next steps:**

- [**`6-echo`**](../6-echo#files) uses Dream and Lwt to read a request body.
- [**`7-template`**](../7-template#files) shows how to interleave HTML and
  OCaml.

<br>

[Up to the tutorial index](../#readme)
