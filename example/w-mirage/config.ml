open Mirage

let main =
  main
    ~packages:[package "dream-mirage"]
    "Unikernel.Hello_world"
    (stackv4v6 @-> job)

let () =
  register "hello" [
    main
      $ generic_stackv4v6 default_network
  ]
