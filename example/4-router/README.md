Now we serve a tiny site dynamic site. If you go to
`http://localhost:8080/echo/foo`, it responds with `foo`. If you change the last
path component to `bar`, it will respond with `bar` instead:

<!-- TODO Link to database example. -->

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/echo/:word"
      (fun request ->
        request
        |> Dream.crumb "word"
        |> Dream.respond);
  ]
  @@ fun _ ->
    Dream.respond ~status:`Not_found ""

```

As you can see, if the router sees a path component that begins with `:`, it
becomes a variable, which can be accessed in the handler by calling
`Dream.crumb`. This example also uses `|>`, the
[standard OCaml operator](https://caml.inria.fr/pub/docs/manual-ocaml/libref/Stdlib.html#VAL(|%3E))
for piping a value into the last argument of a function.

We are now also resonding to `/favicon.ico` and all other requests with
`404 Not Found`, which causes most browsers to stop requesting it after the
first attempt.

<!-- TODO the 404 page. -->

<!-- TODO Link to all the status codes. -->
<!-- TODO API links -->

<br>

Where to go from here?

- [**`5-catch`**](../5-catch) handles errors from all your handlers in one
place.

<!-- TODO Go to SQL example. -->
