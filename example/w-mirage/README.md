# `w-mirage`

<br>

This example shows how to build and use Dream with Mirage. Like any Mirage
starter project, it consists of two files.

`config.ml`:

```ocaml
open Mirage

let main =
  main
    ~packages:[package "dream-mirage"]
    "Unikernel.Hello_world"
    (pclock @-> time @-> stackv4v6 @-> job)

let () =
  register "hello" [
    main
      $ default_posix_clock
      $ default_time
      $ generic_stackv4v6 default_network
  ]
```

`unikernel.ml`:

```ocaml
module Hello_world
  (Pclock : Mirage_clock.PCLOCK)
  (Time : Mirage_time.S)
  (Stack : Tcpip.Stack.V4V6) =
struct
  module Dream =
    Dream__mirage.Mirage.Make (Pclock) (Time) (Stack)

  let start _pclock _time stack =
    Dream.http ~port:8080 (Stack.tcp stack)
    @@ Dream.logger
    @@ fun _ -> Dream.html "Good morning, world!"
end
```

<br>

It's the basic example [**`2-middleware`**](../2-middleware#folders-and-files) adapted to
Mirage. To build and run, do

<pre><code><b>$ cd example/w-mirage</b>
<b>$ opam install mirage</b>
<b>$ mirage configure -t unix</b>
<b>$ make depends</b>
<b>$ dune build --root .</b>
<b>$ _build/default/main.exe</b>
</code></pre>

<br>

[Up to the example index](../#examples)
