(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)

let serve port =
  print_endline "server mode";
  Dream.run ~greeting:false ~port (fun _ -> Unix.sleepf 10.0; Dream.html "Hello")

let client port =
  print_endline "client mode";
  let open Unix in
  let fd = socket PF_INET6 SOCK_STREAM 0 in
  (* force the client to send a TCP RST packet if it fails during connection *)
  setsockopt_optint fd SO_LINGER (Some 0);
  let _ = connect fd (ADDR_INET (inet6_addr_loopback ,port)) in
  ignore @@ failwith "sending RST";
  shutdown fd SHUTDOWN_ALL

let () =
  let server = ref(false) in
  let port = ref(-1) in
  let usage = "Test for ECONNRESET errors being reported" in
  Arg.parse [
    "-p", Set_int port, "sets the port (required)";
    "-s", Set server, "enables the server on port [port], if not set sends a TCP RST on [port]"
  ] (fun _ -> ()) usage;

  let port = !port in
  if port > 65535 || port < 1025 then failwith "Port argument (-p) must set and be between 1025-65535";

  if !server then serve port
  else client port

