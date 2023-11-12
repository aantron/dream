(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let (-:) name f = Alcotest.test_case name `Quick f



let tests = "headers", [

  "header" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    Dream.header request "C"
    |> Alcotest.(check (option string)) "header" (Some "d")
  end;

  "header none" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    Dream.header request "E"
    |> Alcotest.(check (option string)) "header" None
  end;

  "headers" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] "" in
    Dream.headers request "C"
    |> Alcotest.(check (list string)) "headers" ["d"; "e"]
  end;

  "headers empty" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] "" in
    Dream.headers request "F"
    |> Alcotest.(check (list string)) "headers" []
  end;

  "has_header" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    Dream.has_header request "C"
    |> Alcotest.(check bool) "has_header" true
  end;

  "has_header false" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    Dream.has_header request "E"
    |> Alcotest.(check bool) "has_header" false
  end;

  "all_headers" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] "" in
    Dream.all_headers request
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"; "C", "e"]
  end;

  "add_header" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"] "" in
    Dream.add_header request "C" "d";
    Dream.all_headers request
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"]
  end;

  "add_header duplicate" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    Dream.add_header request "A" "e";
    Dream.all_headers request
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "A", "e"; "C", "d"]
  end;

  "add_header compares less" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"] "" in
    Dream.add_header request "A" "a";
    Dream.all_headers request
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "A", "a"; "C", "d"]
  end;

  "drop_header" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "C", "d"; "C", "e"] "" in
    Dream.drop_header request "C";
    Dream.all_headers request
    |> Alcotest.(check (list (pair string string))) "all_headers" ["A", "b"]
  end;

  "drop_header absent" -: begin fun () ->
    let request = Dream.request ~headers:["C", "d"] "" in
    Dream.drop_header request "A";
    Dream.all_headers request
    |> Alcotest.(check (list (pair string string))) "all_headers" ["C", "d"]
  end;

  "with_header" -: begin fun () ->
    let request = Dream.request ~headers:["C", "d"] "" in
    Dream.set_header request "A" "b";
    Dream.all_headers request
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "b"; "C", "d"]
  end;

  "with_header present" -: begin fun () ->
    let request = Dream.request ~headers:["A", "b"; "A", "c"; "D", "e"] "" in
    Dream.set_header request "A" "f";
    Dream.all_headers request
    |> Dream.sort_headers
    |> Alcotest.(check (list (pair string string))) "all_headers"
      ["A", "f"; "D", "e"]
  end;

]
