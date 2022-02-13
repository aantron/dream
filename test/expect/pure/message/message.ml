(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2022 Anton Bachin *)



let%expect_test _ =
  let handler _ =
    print_endline "handler";
    Dream.empty `OK
  in
  let inner_middleware handler request =
    print_endline "inner middleware: request";
    let%lwt response = handler request in
    print_endline "inner middleware: response";
    Lwt.return response
  in
  let outer_middleware handler request =
    print_endline "outer middleware: request";
    let%lwt response = handler request in
    print_endline "outer middleware: response";
    Lwt.return response
  in
  let server =
    Dream.pipeline [
      outer_middleware;
      inner_middleware
    ]
    @@ handler
  in
  ignore (Lwt_main.run (server (Dream.request "")));
  [%expect {|
    outer middleware: request
    inner middleware: request
    handler
    inner middleware: response
    outer middleware: response |}]
