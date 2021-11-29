open Mirage

let port =
  let doc = Key.Arg.info ~doc:"Listening port." [ "port" ] in
  Key.(create "port" Arg.(opt int 443 doc))

let hostname =
  let doc = Key.Arg.info ~doc:"Hostname." [ "hostname" ] in
  Key.(create "hostname" Arg.(opt string "localhost" doc))

let production =
  let doc = Key.Arg.info ~doc:"Let's encrypt production environment." [ "production" ] in
  Key.(create "production" Arg.(opt bool false doc))

let cert_seed =
  let doc = Key.Arg.info ~doc:"Let's encrypt certificate seed." [ "cert-seed" ] in
  Key.(create "cert_seed" Arg.(opt (some string) None doc))

let account_seed =
  let doc = Key.Arg.info ~doc:"Let's encrypt account seed." [ "account-seed" ] in
  Key.(create "account_seed" Arg.(opt (some string) None doc))

let email =
  let doc = Key.Arg.info ~doc:"Let's encrypt E-Mail." [ "email" ] in
  Key.(create "email" Arg.(opt (some string) None doc))

let tls =
  let doc = Key.Arg.info ~doc:"HTTP server with TLS." [ "tls" ] in
  Key.(create "tls" Arg.(opt bool false doc))

let letsencrypt =
  let doc = Key.Arg.info ~doc:"Retrieve the TLS certificate from Let's encrypt." [ "letsencrypt" ] in
  Key.(create "letsencrypt" Arg.(opt bool false doc))

let dream =
  foreign "Unikernel.Make"
    ~packages:[ package "ca-certs-nss"
              ; package "dns-client" ~sublibs:[ "mirage" ]
              ; package "dream-mirage" ~sublibs:[ "paf.le" ]
              ; package "checkseum" ~sublibs:[ "c" ]
              ; package "dream-mirage" ]
    ~keys:Key.([ abstract port
               ; abstract hostname
               ; abstract production
               ; abstract cert_seed
               ; abstract account_seed
               ; abstract email
               ; abstract tls
               ; abstract letsencrypt ])
    (console @-> random @-> time @-> mclock @-> pclock @-> stackv4v6 @-> job)

let random = default_random
let console = default_console
let time = default_time
let pclock = default_posix_clock
let mclock = default_monotonic_clock
let stackv4v6 = generic_stackv4v6 default_network

let () = register "dream"
  [ dream $ console $ random $ time $ mclock $ pclock $ stackv4v6 ]
