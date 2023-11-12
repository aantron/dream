(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let encode string =
  Printf.printf "%S\n" (Dream.to_base64url string)

let%expect_test _ =
  encode "a";
  encode "b";
  encode "\xFF";
  encode "\xFB";
  encode "abc";
  encode "abcdef";
  encode "abcde";
  encode "";
  [%expect {|
    "YQ"
    "Yg"
    "_w"
    "-w"
    "YWJj"
    "YWJjZGVm"
    "YWJjZGU"
    "" |}]

let decode string =
  match Dream.from_base64url string with
  | Some string -> Printf.printf "%S\n" string
  | None -> print_endline "None"

let%expect_test _ =
  decode "YWJj";
  decode "YQ";
  decode "YQ==";
  decode "+";
  [%expect {|
    "abc"
    "a"
    "a"
    None |}]
