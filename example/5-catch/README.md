Insert the `Dream.catch` middleware to have it handle all errors and exceptions
in one place:

<!-- TODO Link to database example. -->

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.catch ~debug:true
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/bad"
      (fun _ ->
        Dream.respond ~status:`Bad_request "");

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The web app had a fail!"));

  ]
  @@ fun _ ->
    Dream.respond ~status:`Not_found ""
```

<!-- TODO Show the debugger output -->
<!-- TODO Mention ?template, ?on_error, ?on_exn -->
<!-- TODO Recommend empty responses -->
<!-- TODO Show the log -->
<!-- TODO Point out backtraces -->
<!-- TODO Explain first and last request tracking -->

<br>

Where to go from here?

- [**`5-catch`**](../5-catch) handles errors from all your handlers in one
place.

<!-- TODO Go to SQL example. -->
