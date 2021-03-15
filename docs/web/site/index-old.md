Dream is built on only five types:

```ocaml
type request
type response

type handler = request -> response promise
type middleware = handler -> handler
type route
```

`request` and `response` are the data types of Dream. Requests contain all the
interesting fields your application will want to read, and the application will
handle requests by creating and returning responses.

The other three types are for building up such request-handling functions.

<br>

`handler`s are asynchronous functions from requests to responses. They are just
bare functions &mdash; you can define a handler immediately:

```ocaml
let greet _ =
  Dream.respond "Hello, world!"
```

Whenever you have a handler, you can pass it to `Dream.run` to turn it into a
working HTTP server:

```ocaml
let () =
  Dream.run (fun _ ->
    Dream.respond "Hello, world!")
```

This server responds to all requests with status `200 OK` and body `Hello, world!`.

`middleware`s are functions that take a handler, and run some code before or
after the handler runs. The result is a “bigger” handler. Middlewares are
also just bare functions, so you can also create them immediately:

```ocaml
let log_requests inner_handler =
  fun request ->
    Dream.log "Got a request!";
    inner_handler request
```

This middleware prints a message on every request, before passing the
request to the rest of the app. You can use it with `Dream.run`:

```ocaml
let () =
  Dream.run
  @@ log_requests
  @@ greet
```

The `@@` is just the ordinary function-calling operator from OCaml's
standard library. The above code is the same as

```ocaml
let () =
  Dream.run (log_requests greet)
```

However, as we chain more and more middlewares, there will be more and more
nested parentheses. `@@` is just a neat way to avoid that.

`route`s are used with `Dream.router` to select which handler each request
should go to. They are created with helpers like `Dream.get` and
`Dream.scope`:

```ocaml

```

If you prefer a vaguely “algebraic” take on Dream:

- Literal `handler`s are atoms.
- `middleware` is for sequential composition (AND-like).
- `route` is for alternative composition (OR-like).

<br/>




Dream is a ...

<!-- TODO DOC -->
Need to do:

- This main page. It should serve as a neat landing and immediate tutorial.
- API reference.
  - Probably with some tooltips, etc., courtesy of React+material.
  - Can try to run odoc... but at least the signatures will DEFINITELY need rewriting.
- Guides.

Testing mdx:

```ocaml
print_endline (string_of_int 42)
```
