open Mirage

let port =
  let doc = Key.Arg.info ~doc:"port of HTTP service." [ "p"; "port" ] in
  Key.(create "port" Arg.(opt (some int) None doc))

let dream =
  foreign "Unikernel.Make"
    ~keys:[ Key.abstract port ]
    ~packages:[ package "dream" ~sublibs:[ "mirage" ] ]
    (time @-> stackv4v6 @-> job)

let () = register "dream" [ dream $ default_time $ generic_stackv4v6 default_network ]
