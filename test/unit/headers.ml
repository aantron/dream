(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let (-:) name f = Alcotest.test_case name `Quick f



let tests = "headers", [


  "header" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"] ""
    |> Dream.header "C"
    |> Alcotest.(check (option string)) "header" (Some "d")

  end;


  "header none" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"] ""
    |> Dream.header "E"
    |> Alcotest.(check (option string)) "header" None

  end;


  "headers" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] ""
    |> Dream.headers "C"
    |> Alcotest.(check (list string)) "headers" ["d"; "e"]

  end;


  "headers empty" -: begin fun () ->
    Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] ""
    |> Dream.headers "F"
    |> Alcotest.(check (list string)) "headers" []

  end;


  "has_header" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"] ""
    |> Dream.has_header "C"
    |> Alcotest.(check bool) "has_header" true

  end;


  "has_header false" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"] ""
    |> Dream.has_header "E"
    |> Alcotest.(check bool) "has_header" false

  end;


  "all_headers" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] ""
    |> Dream.all_headers
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"; "C", "e"]

  end;


  "add_header" -: begin fun () ->

    Dream.request ~headers:["A", "b"] ""
    |> Dream.add_header "C" "d"
    |> Dream.all_headers
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"]

  end;


  "add_header duplicate" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"] ""
    |> Dream.add_header "A" "e"
    |> Dream.all_headers
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "A", "e"; "C", "d"]

  end;


  "add_header compares less" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"] ""
    |> Dream.add_header "A" "a"
    |> Dream.all_headers
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "A", "a"; "C", "d"]

  end;


  "add_header immutable" -: begin fun () ->

    let first = Dream.request ~headers:["A", "b"] "" in
    let last  = Dream.add_header "C" "d" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"] (Dream.sort_headers (Dream.all_headers first))

  end;


  "add_header update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.add_header "A" "b" first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;


  "drop_header" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] ""
    |> Dream.drop_header "C"
    |> Dream.all_headers
    |> Alcotest.(check (list (pair string string))) "all_headers" ["A", "b"]

  end;


  "drop_header absent" -: begin fun () ->

    Dream.request ~headers:["C", "d"] ""
    |> Dream.drop_header "A"
    |> Dream.all_headers
    |> Alcotest.(check (list (pair string string))) "all_headers" ["C", "d"]

  end;


  "drop_header immutable" -: begin fun () ->

    let first = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    let last  = Dream.drop_header "A" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"] (Dream.sort_headers (Dream.all_headers first))

  end;


  (* If the optimization to return the same request upon missing headers is
     implemented, this test will rightly fail, and will need inversion of the
     check "different." *)
  "drop_header absent reuse" -: begin fun () ->

    let first = Dream.request ~headers:["C", "d"] "" in
    let last  = Dream.drop_header "A" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check (list (pair string string))) "all_headers"
      ["C", "d"] (Dream.sort_headers (Dream.all_headers first))

  end;


  "drop_header update" -: begin fun () ->

    let first = Dream.request ~headers:["A", "b"] "" in
    let last  = Dream.drop_header "A" first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;


  "with_header" -: begin fun () ->

    Dream.request ~headers:["C", "d"] ""
    |> Dream.with_header "A" "b"
    |> Dream.all_headers
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"]

  end;


  "with_header present" -: begin fun () ->

    Dream.request ~headers:["A", "b"; "A", "c"; "D", "e"] ""
    |> Dream.with_header "A" "f"
    |> Dream.all_headers
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "f"; "D", "e"]

  end;


  "with_header immutable" -: begin fun () ->

    let first = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    let last  = Dream.with_header "A" "e" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"] (Dream.sort_headers (Dream.all_headers first))

  end;


  "with_header update" -: begin fun () ->

    let first = Dream.request ~headers:["A", "b"] "" in
    let last  = Dream.with_header "A" "c" first in

    Alcotest.(check bool) "last"  true (Dream.last first == last);
    Alcotest.(check bool) "last"  true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;
]
