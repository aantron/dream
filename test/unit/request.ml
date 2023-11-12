(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let (-:) name f = Alcotest.test_case name `Quick f



let tests = "request", [

  "with_client" -: begin fun () ->
    let request = Dream.request "" in
    Dream.set_client request "2.3.4.5:34567";
    Dream.client request
    |> Alcotest.(check string) "client" "2.3.4.5:34567"
  end;

  "method_" -: begin fun () ->
    Dream.request ~method_:`POST ""
    |> Dream.method_
    |> Dream.method_to_string
    |> Alcotest.(check string) "method_" "POST"
  end;

  "with_method_" -: begin fun () ->
    let request = Dream.request "" in
    Dream.set_method_ request `PUT;
    Dream.method_ request
    |> Dream.method_to_string
    |> Alcotest.(check string) "method_" "PUT";
  end;

  "target" -: begin fun () ->
    Dream.request ~target:"/foo" ""
    |> Dream.target
    |> Alcotest.(check string) "target" "/foo"
  end;

]
