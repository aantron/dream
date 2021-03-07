# Testing

Testing framework design.

1. Needs to be built into Dream.
2. Needs to support unit testing of handlers.
3. Needs to support end-to-end testing of web app configs.

```ocaml
Dream.test : handler -> request -> response Lwt.t
(* Is this even necessary? The user can just call the handler... however,
yes, it is necessary. The test function should create an app context for
the handler to run in, so that the test is repeatable.

This is, in fact, a middleware, by type - but not by functionality.

It needs to create an app context and apply all the built-in
middlewares. Perhaps with an option for not doing the latter. *)
```

```ocaml
Dream.dump : _ message -> string
(* ... or something else? Format? *)
(* Doing it this way will require a tagged representation. Is there
anything else besides messages to dump? App and message contexts will
be dumped with the messages. *)
```

- An end-to-end test will take a lot of arguments &mdash; most of the arguments of run or serve.

```ocaml
Dream.round_trip : string -> string Lwt.t
```

The testers will insert some kind of middleware to sort response headers.

The basic module `Inmost` essentially consists of just a bunch of accessors.
They have a *few* non-trivial behaviors, but mainly not. The interesting bits
are just the body streaming. And, indeed, the base API doesn't really do
anything on its own &mdash; it's only there to serve as a basis for writing more
interesting things.

So, in the core library, the middleware is interesting from the point of view of
testing. This is what contains various state machines, etc. For a simplest
example, how does one test the request_id middleware? Probably need to create a
custom handler that does some assertions about having a request id; that the
request ids grow sequentially; that the request id sequences are scoped to an
"app," that they appear in debugger dumps... That they are assigned even when
not explicitly passing a request. Also need to test that the HTTP server
integration is handling this correctly, so start the web server...

How to test the logger? Probably need a way to replace the time function, and
spawn a subprocess to capture its STDERR.
