open Rresult
open Lwt.Infix

let ( <.> ) f g = fun x -> f (g x)

module Make
  (_ : Mirage_console.S)
  (Random : Mirage_random.S)
  (Time : Mirage_time.S)
  (Mclock : Mirage_clock.MCLOCK)
  (Pclock : Mirage_clock.PCLOCK)
  (Stack : Mirage_stack.V4V6) = struct
  module Dream = Dream__mirage.Mirage.Make (Pclock) (Time) (Stack)
  
  let echo request = Dream.html (Dream.param "word" request)
  let ( >>? ) = Lwt_result.bind
  
  let dream =
    Dream.logger
    @@ Dream.router
    [ Dream.get "/" (fun _ -> Dream.html "Good morning, world! (from MirageOS)")
    ; Dream.get "/echo/:word" echo ]

  module DNS = Dns_client_mirage.Make (Random) (Time) (Mclock) (Pclock) (Stack)
  module Let = LE.Make (Time) (Stack)
  module Nss = Ca_certs_nss.Make (Pclock)
  module Paf = Paf_mirage.Make (Time) (Stack)

  let authenticator = R.failwith_error_msg (Nss.authenticator ())

  let gethostbyname dns domain_name = DNS.gethostbyname dns domain_name >>? fun ipv4 ->
    Lwt.return_ok (Ipaddr.V4 ipv4)

  let error_handler _ ?request:_ _ _ = ()

  let get_certificates ?(production= false) cfg stackv4v6 =
    Paf.init ~port:80 (Stack.tcp stackv4v6) >>= fun t ->
    let service = Paf.http_service ~error_handler Let.request_handler in
    Lwt_switch.with_switch @@ fun stop ->
    let `Initialized th = Paf.serve ~stop service t in
    let ctx = Let.ctx ~gethostbyname ~authenticator (DNS.create stackv4v6) stackv4v6 in
    let fiber =
      Let.provision_certificate ~production cfg ctx >>= fun certificates ->
      Lwt_switch.turn_off stop >>= fun () -> Lwt.return certificates in
    Lwt.both th fiber >>= function
    | ((), Ok certificates) -> Lwt.return certificates
    | ((), Error (`Msg err)) -> failwith err

  let https_with_letsencrypt stackv4v6 =
    let cfg =
      { LE.certificate_seed= Key_gen.cert_seed ()
      ; LE.certificate_key_type= `ED25519
      ; LE.certificate_key_bits= None
      ; LE.email= Option.bind (Key_gen.email ()) (R.to_option <.> Emile.of_string)
      ; LE.account_seed= Key_gen.account_seed ()
      ; LE.account_key_type= `ED25519
      ; LE.account_key_bits= None
      ; LE.hostname= Domain_name.(host_exn <.> of_string_exn) (Key_gen.hostname ()) } in
    get_certificates ~production:(Key_gen.production ()) cfg stackv4v6 >>= fun certificates -> 
    let tls = Tls.Config.server ~certificates () in
    Dream.https ~port:(Key_gen.port ()) (Stack.tcp stackv4v6) ~cfg:tls dream

  let https stackv4v6 =
    Dream.https ~port:(Key_gen.port ()) (Stack.tcp stackv4v6) dream

  let http stackv4v6 =
    Dream.http ~port:(Key_gen.port ()) (Stack.tcp stackv4v6) dream

  let start _console () () () () stackv4v6 =
    match Key_gen.tls (), Key_gen.letsencrypt () with
    | true, true -> https_with_letsencrypt stackv4v6
    | true, false -> https stackv4v6
    | false, _ -> http stackv4v6
end
