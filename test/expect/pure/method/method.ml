(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let show method_ =
  Printf.printf "%S\n" (Dream.method_to_string method_)

let%expect_test _ =
  show `GET;
  show `POST;
  show `PUT;
  show `DELETE;
  show `HEAD;
  show `CONNECT;
  show `OPTIONS;
  show `TRACE;
  show `PATCH;
  show (`Method "FOO");
  show (`Method "");
  [%expect {|
    "GET"
    "POST"
    "PUT"
    "DELETE"
    "HEAD"
    "CONNECT"
    "OPTIONS"
    "TRACE"
    "PATCH"
    "FOO"
    "" |}]

let of_string string =
  match Dream.string_to_method string with
  | `Method string -> Printf.printf "string %S\n" string
  | method_ -> show method_

let%expect_test _ =
  of_string "GET";
  of_string "POST";
  of_string "PUT";
  of_string "DELETE";
  of_string "HEAD";
  of_string "CONNECT";
  of_string "OPTIONS";
  of_string "TRACE";
  of_string "PATCH";
  of_string "";
  of_string "get";
  of_string "FOO";
  [%expect {|
    "GET"
    "POST"
    "PUT"
    "DELETE"
    "HEAD"
    "CONNECT"
    "OPTIONS"
    "TRACE"
    "PATCH"
    string ""
    string "get"
    string "FOO" |}]

let normalize method_ =
  let result = Dream.normalize_method method_ in
  match result with
  | `Method method_ ->
    Printf.printf "%S\n" method_
  | _ ->
    Printf.printf "`%s\n" (Dream.method_to_string result)

let%expect_test _ =
  normalize `GET;
  normalize (`Method "GET");
  normalize (`Method "get");
  normalize `POST;
  normalize (`Method "POST");
  normalize `PUT;
  normalize (`Method "PUT");
  normalize `DELETE;
  normalize (`Method "DELETE");
  normalize `HEAD;
  normalize (`Method "HEAD");
  normalize `CONNECT;
  normalize (`Method "CONNECT");
  normalize `OPTIONS;
  normalize (`Method "OPTIONS");
  normalize `TRACE;
  normalize (`Method "TRACE");
  normalize `PATCH;
  normalize (`Method "PATCH");
  [%expect {|
    `GET
    `GET
    "get"
    `POST
    `POST
    `PUT
    `PUT
    `DELETE
    `DELETE
    `HEAD
    `HEAD
    `CONNECT
    `CONNECT
    `OPTIONS
    `OPTIONS
    `TRACE
    `TRACE
    `PATCH
    `PATCH |}]

let equal method_1 method_2 =
  Printf.printf "%B\n" (Dream.methods_equal method_1 method_2)

let%expect_test _ =
  equal `GET `GET;
  equal `POST `POST;
  equal `GET `POST;
  equal `POST `GET;
  equal `GET (`Method "GET");
  equal (`Method "GET") `GET;
  equal `GET (`Method "get");
  [%expect {|
    true
    true
    false
    false
    true
    true
    false |}]
