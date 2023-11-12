(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let encode ?international s =
  Printf.printf "%S\n" (Dream.to_percent_encoded ?international s)

let%expect_test _ =
  encode "";
  encode "a/ λ";
  encode ~international:false "a/ λ";
  [%expect {|
    ""
    "a%2F%20\206\187"
    "a%2F%20%CE%BB" |}]

let decode s =
  Printf.printf "%S\n" (Dream.from_percent_encoded s)

let%expect_test _ =
  decode "";
  decode "%";
  decode "%2";
  decode "%20";
  decode " ";
  decode "%z";
  decode "%zz";
  decode "%1A";
  decode "λ%CE%BB";
  [%expect {|
    ""
    "%"
    "%2"
    " "
    " "
    "%z"
    "%zz"
    "\026"
    "\206\187\206\187" |}]
