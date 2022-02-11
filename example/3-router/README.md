# `3-router`

<br>

A [*router*](https://aantron.github.io/dream/#routing) sends requests to
different handlers, depending on their method and path. In this example, we
still serve `Good morning, world!` at our site root, `/`. But, we have a
different response for `GET` requests to `/echo/*`, and we respond to
everything else with `404 Not Found`:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.html "Good morning, world!");

    Dream.get "/echo/:word"
      (fun request ->
        Dream.html (Dream.param request "word"));

  ]
```

<pre><code><b>$ cd example/3-router</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

This is also our first dynamic site! A request to `/echo/foo` gets the response
`foo`, and a request to `/echo/bar` gets `bar`! Try it in the
[playground](http://dream.as/3-router/echo/foo) &mdash; once the server loads,
edit the URL in the right pane to visit `/echo/bar`.

The syntax `:word` in a route creates a path parameter, which can be read with
[`Dream.param`](https://aantron.github.io/dream/#val-param).

<!-- TODO hyperlink Dream.param to docsc, also Dream.logger. -->

When none of the routes match, the router returns a `404 Not Found` response.
Except for the status code, the `404 Not Found` response is *completely* empty,
so it might not display well in your browser. In example
[**`9-error`**](../9-error#files), we will decorate all error responses with
an error template in one central location.

<br>

The router can do more than match simple routes:

- [**`f-static`**](../f-static#files) forwards all requests with a certain
  prefix to a static file handler.


<!-- - [**`w-scope`**](../w-scope/#files) applies middlewares to groups of routes
  &mdash; but only when they match.
- [**`w-subsite`**](../w-subsite/#files) attaches a handler as a complete,
  nested sub-site, which might have its own router. -->
<!-- TODO -->

<br>

**Next steps:**

- [**`4-counter`**](../4-counter#files) counts requests, and exposes a route for
  getting the count.
- [**`5-promise`**](../5-promise#files) introduces
  [Lwt](https://github.com/ocsigen/lwt), the promise library used by Dream.

<br>

[Up to the tutorial index](../#readme)
