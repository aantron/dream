let show_method method_ =
  print_endline (Dream.method_to_string method_)

let%expect_test _ =
  show_method `GET;
  show_method `POST;
  show_method `PUT;
  show_method `DELETE;
  show_method `HEAD;
  show_method `CONNECT;
  show_method `OPTIONS;
  show_method `TRACE;
  show_method (`Method "FOO");
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
