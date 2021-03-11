(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let show method_ =
  print_endline (Dream.method_to_string method_)

let%expect_test _ =
  show `GET;
  show `POST;
  show `PUT;
  show `DELETE;
  show `HEAD;
  show `CONNECT;
  show `OPTIONS;
  show `TRACE;
  show (`Method "FOO");
  [%expect {|
    GET
    POST
    PUT
    DELETE
    HEAD
    CONNECT
    OPTIONS
    TRACE
    FOO |}]
