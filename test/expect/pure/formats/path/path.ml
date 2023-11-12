(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let decode string =
  string
  |> Dream.from_path
  |> List.map (Printf.sprintf "%S")
  |> String.concat " "
  |> Printf.printf "[%s]\n"

let%expect_test _ =
  decode "";
  decode "/";
  decode "abc";
  decode "abc/";
  decode "/abc/";
  decode "//abc/";
  decode "a%2Fb";
  decode "a/b";
  decode "a//b";
  decode "%CE%BB";
  decode "/λ/λ";
  decode "/%Ce%bB";
  decode "/%c";
  decode "/%c/";
  decode "/%cg";
  decode "/%";
  decode "/%/";
  [%expect {|
    []
    [""]
    ["abc"]
    ["abc" ""]
    ["abc" ""]
    ["abc" ""]
    ["a/b"]
    ["a" "b"]
    ["a" "b"]
    ["\206\187"]
    ["\206\187" "\206\187"]
    ["\206\187"]
    ["%c"]
    ["%c" ""]
    ["%cg"]
    ["%"]
    ["%" ""] |}]

let drop path =
  path
  |> Dream.drop_trailing_slash
  |> List.map (Printf.sprintf "%S")
  |> String.concat " "
  |> Printf.printf "[%s]\n"

let%expect_test _ =
  drop ["a"];
  drop ["a"; ""];
  drop ["a"; "b"];
  drop ["a"; "b"; ""];
  [%expect {|
    ["a"]
    ["a"]
    ["a" "b"]
    ["a" "b"] |}]

let encode ?relative ?international components =
  Dream.to_path ?relative ?international components
  |> Printf.printf "%S\n"

let%expect_test _ =
  encode [];
  encode [""];
  encode ["a"];
  encode ["a"; "b"];
  encode ["/"; "?"; "%AB"; "λ"];
  encode ["a"; ""];
  encode [""; "a"];
  encode ["a"; ""; "b"];
  encode ~relative:true [];
  encode ~relative:true [""];
  encode ~relative:true ["a"];
  encode ~relative:true ["a"; ""];
  encode ~relative:true [""; "a"];
  encode ~international:false ["λ"];
  [%expect {|
    "/"
    "/"
    "/a"
    "/a/b"
    "/%2F/%3F/%25AB/\206\187"
    "/a/"
    "/a"
    "/a/b"
    ""
    ""
    "a"
    "a/"
    "a"
    "/%CE%BB" |}]
