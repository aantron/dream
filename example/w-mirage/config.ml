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
