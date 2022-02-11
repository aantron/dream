# `4-counter`

<br>

This example shows how easy it is to define a custom middleware,
`count_requests`. It exposes the request count at
[http://localhost:8080/](http://localhost:8080/)
[[playground](http://dream.as/4-counter)], in a sort of dashboard:

```ocaml
let count = ref 0

let count_requests inner_handler request =
  count := !count + 1;
  inner_handler request

let () =
  Dream.run
  @@ Dream.logger
  @@ count_requests
  @@ Dream.router [
    Dream.get "/" (fun _ ->
      Dream.html (Printf.sprintf "Saw %i request(s)!" !count));
  ]
```
<pre><code><b>$ cd example/4-counter</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

As you can see, defining middlewares in Dream is completely trivial! They are
[just functions](https://aantron.github.io/dream/#type-middleware) that take an
`inner_handler` as a parameter, and wrap it. They act like handlers themselves,
which means they usually also
[take a `request`](https://aantron.github.io/dream/#type-handler).

This example's middleware only does something *before* calling the
`inner_handler`. To do something *after*, we will need to await the response
promise with [Lwt](https://github.com/ocsigen/lwt#readme), the promise library
used by Dream. The next example, [**`5-promise`**](../5-promise#files), does
exactly that!

<br>

**Next steps:**

- [**`5-promise`**](../5-promise#files) shows a middleware that awaits
  responses using [Lwt](https://github.com/ocsigen/lwt).
- [**`6-echo`**](../6-echo#files) responds to `POST` requests and reads their
  bodies.

<br>

[Up to the tutorial index](../#readme)
