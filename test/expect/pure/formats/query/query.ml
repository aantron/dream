(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let query name string =
  Dream.query (Dream.request ~target:("/?" ^ string) "") name
  |> function
    | Some value -> Printf.printf "%S\n" value
    | None -> print_endline "None"

let%expect_test _ =
  query "a" "a=b";
  query "" "a=b";
  query "" "";
  query "a" "";
  query "a" "a=";
  query "" "=a";
  query "a" "a=b&a=c";
  query "c" "a=b&c=d";
  query "a b" "a+b=c";
  [%expect {|
    "b"
    None
    None
    None
    ""
    "a"
    "b"
    "d"
    "c" |}]



let queries name string =
  Dream.queries (Dream.request ~target:("/?" ^ string) "") name
  |> List.map (Printf.sprintf "%S")
  |> String.concat " "
  |> Printf.printf "[%s]\n"

let%expect_test _ =
  queries "a" "a=b";
  queries "" "a=b";
  queries "" "";
  queries "a" "";
  queries "a" "a=";
  queries "" "=a";
  queries "a" "a=b&a=c";
  queries "c" "a=b&c=d";
  queries "a b" "a+b=c";
  [%expect {|
    ["b"]
    []
    []
    []
    [""]
    ["a"]
    ["b" "c"]
    ["d"]
    ["c"] |}]



let all_queries string =
  Dream.request ~target:("/?" ^ string) ""
  |> Dream.all_queries
  |> List.map (fun (name, value) -> Printf.sprintf "%S=%S" name value)
  |> String.concat " "
  |> Printf.printf "[%s]\n"

let%expect_test _ =
  all_queries "a=b";
  all_queries "a=b&a=c";
  all_queries "";
  all_queries "=";
  all_queries "a+b=c+d";
  [%expect {|
    ["a"="b"]
    ["a"="b" "a"="c"]
    []
    [""=""]
    ["a b"="c d"] |}]
