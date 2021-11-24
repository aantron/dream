(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let escape string =
  Printf.printf "%S\n" (Dream.html_escape string)

let%expect_test _ =
  escape "";
  escape "foo";
  escape "<foo>";
  escape "&amp;";
  escape "<foo bar=\"baz\">";
  escape "<foo bar=\'baz\'>";
  [%expect {|
    ""
    "foo"
    "&lt;foo&gt;"
    "&amp;amp;"
    "&lt;foo bar=&quot;baz&quot;&gt;"
    "&lt;foo bar=&#x27;baz&#x27;&gt;" |}]
