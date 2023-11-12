(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let encode dictionary =
  dictionary
  |> Dream.to_form_urlencoded
  |> Printf.printf "%S\n"

let%expect_test _ =
  encode [];
  encode ["a", ""];
  encode ["", "a"];
  encode ["", ""];
  encode ["a", "b"];
  encode ["a b", "c d"];
  encode ["a+=&", "b+=&"];
  encode ["λ", "Λ"];
  encode ["a", "b"; "a", "c"];
  encode ["a", "b,c"];
  [%expect {|
    ""
    "a="
    "=a"
    "="
    "a=b"
    "a%20b=c%20d"
    "a%2B%3D%26=b%2B=%26"
    "%CE%BB=%CE%9B"
    "a=b&a=c"
    "a=b%2Cc" |}]



let decode string =
  string
  |> Dream.from_form_urlencoded
  |> List.iter (fun (name, value) -> Printf.printf "%S = %S\n" name value)

let%expect_test _ =
  decode "";
  [%expect {| |}]

let%expect_test _ =
  decode "=";
  [%expect {| "" = "" |}]

let%expect_test _ =
  decode "ab=cd";
  [%expect {| "ab" = "cd" |}]

let%expect_test _ =
  decode "a+b=c+d";
  [%expect {| "a b" = "c d" |}]

let%expect_test _ =
  decode "a%CE%BBb=c%CE%BBd";
  [%expect {| "a\206\187b" = "c\206\187d" |}]

let%expect_test _ =
  decode " %3D=%26%2Ba ";
  [%expect {| " =" = "&+a " |}]

let%expect_test _ =
  decode "abc";
  [%expect {| "abc" = "" |}]

let%expect_test _ =
  decode "abc=";
  [%expect {| "abc" = "" |}]

let%expect_test _ =
  decode "=abc";
  [%expect {| "" = "abc" |}]

let%expect_test _ =
  decode "a=b&c=d";
  [%expect {|
    "a" = "b"
    "c" = "d" |}]

let%expect_test _ =
  decode "a=b,c";
  [%expect {| "a" = "b,c" |}]

let%expect_test _ =
  decode "a=b&a=c";
  [%expect {|
    "a" = "b"
    "a" = "c" |}]
