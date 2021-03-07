module A = Alcotest
let test_case name f = A.test_case name `Quick f



let tests = "pure", [

  test_case "method_to_string" begin fun () ->

    let check name method_ =
      A.(check string) name name (Dream.method_to_string method_) in

    check "GET"     `GET;
    check "POST"    `POST;
    check "PUT"     `PUT;
    check "DELETE"  `DELETE;
    check "HEAD"    `HEAD;
    check "CONNECT" `CONNECT;
    check "OPTIONS" `OPTIONS;
    check "TRACE"   `TRACE;
    check "FOO"    (`Other "FOO");

  end;

]
