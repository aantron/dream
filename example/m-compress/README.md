# `m-compress`

<br>

Demonstrate how to compress responses using the `Dream.compress` middleware.

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.compress
  @@ Dream.router [ Dream.get "/" (fun _ -> Dream.html "Hello World!") ]
```

The middleware will parse the `Accept-Encoding` header from the requests and compress the responses accordingly.

## Limitation

As of now, the only supported encoding directives are `gzip` and `deflate`.

Support for more compression methods will come when they are supported in `decompress`, the underlying compression library used in `dream-encoding`.

<br>

[Up to the tutorial index](../#readme)
