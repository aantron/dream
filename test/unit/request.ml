(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let (-:) name f = Alcotest.test_case name `Quick f



let tests = "request", [


  "client" -: begin fun () ->

    Dream.request ~client:"1.2.3.4:23456" ""
    |> Dream.client
    |> Alcotest.(check string) "client" "1.2.3.4:23456"

  end;


  "with_client" -: begin fun () ->

    Dream.request ""
    |> Dream.with_client "2.3.4.5:34567"
    |> Dream.client
    |> Alcotest.(check string) "client" "2.3.4.5:34567"

  end;


  "with_client immutable" -: begin fun () ->

    let first = Dream.request ~client:"1.2.3.4:23456" "" in
    let last  = Dream.with_client "2.3.4.5:34567" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check string) "client" "1.2.3.4:23456" (Dream.client first);

  end;


  "with_client update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.with_client "1.2.3.4:23456" first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;


  "method_" -: begin fun () ->

    Dream.request ~method_:`POST ""
    |> Dream.method_
    |> Dream.method_to_string
    |> Alcotest.(check string) "method_" "POST"

  end;


  "with_method_" -: begin fun () ->

    Dream.request ""
    |> Dream.with_method_ `PUT
    |> Dream.method_
    |> Dream.method_to_string
    |> Alcotest.(check string) "method_" "PUT";

  end;


  "with_method_ immutable" -: begin fun () ->

    let first = Dream.request ~method_:`DELETE "" in
    let last  = Dream.with_method_ `HEAD first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check string) "method_" "DELETE"
      (Dream.method_to_string (Dream.method_ first))

  end;


  "with_method_ update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.with_method_ `TRACE first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;


  "target" -: begin fun () ->

    Dream.request ~target:"/foo" ""
    |> Dream.target
    |> Alcotest.(check string) "target" "/foo"

  end;


  (* "with_target" -: begin fun () ->

    Dream.request ""
    |> Dream.with_target "/bar"
    |> Dream.target
    |> Alcotest.(check string) "target" "/bar";

  end;


  "with_target immutable" -: begin fun () ->

    let first = Dream.request ~target:"/bar" "" in
    let last  = Dream.with_target "/foo" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check string) "target" "/bar" (Dream.target first)

  end;


  "with_target update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.with_target "/foo" first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end; *)


  (* "prefix" -: begin fun () ->

    Dream.request ~prefix:"/foo" ""
    |> Dream.prefix
    |> Alcotest.(check string) "prefix" "/foo"

  end;


  "with_prefix" -: begin fun () ->

    Dream.request ""
    |> Dream.with_prefix "/bar"
    |> Dream.prefix
    |> Alcotest.(check string) "prefix" "/bar";

  end;


  "with_prefix immutable" -: begin fun () ->

    let first = Dream.request ~prefix:"/bar" "" in
    let last  = Dream.with_prefix "/foo" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check string) "prefix" "/bar" (Dream.prefix first)

  end;


  "with_prefix update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.with_prefix "/foo" first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end; *)


  "version" -: begin fun () ->

    Dream.request ~version:(0, 5) ""
    |> Dream.version
    |> Alcotest.(check (pair int int)) "version" (0, 5)

  end;


  "with_version" -: begin fun () ->

    Dream.request ""
    |> Dream.with_version (0, 6)
    |> Dream.version
    |> Alcotest.(check (pair int int)) "version" (0, 6);

  end;


  "with_version immutable" -: begin fun () ->

    let first = Dream.request ~version:(0, 7) "" in
    let last  = Dream.with_version (0, 8) first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check (pair int int)) "version" (0, 7) (Dream.version first)

  end;


  "with_version update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.with_version (0, 9) first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;

]
