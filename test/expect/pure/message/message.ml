(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2022 Anton Bachin *)

let%expect_test "middleware runs sequentially" =
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


module Message = Dream_pure.Message
module Stream = Dream_pure.Stream

let%expect_test "no empty headers" =
  let bad_headers = ["", ""; "", "value-with-empty-key" ; "content-type", "application/json"; "custom-key", "custom-value"] in
  let response = Message.response ~headers:bad_headers Stream.null Stream.null in
  let headers = Dream.all_headers response |> List.fold_left (fun acc (key, value) -> Printf.sprintf "%s %s: %s" acc key value) ""  in
  print_string headers;
  [%expect {| content-type: application/json custom-key: custom-value |}]