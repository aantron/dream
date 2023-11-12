(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let decode string =
  string
  |> Dream.split_target
  |> fun (path, query) -> Printf.printf "%S %S\n" path query

let%expect_test _ =
  decode "";
  decode "?";
  decode "/";
  decode "/?";
  decode "/abc/def";
  (* TODO A very questionable interpretation of // as leading a hostname when we
     know this is a target. There seems to be no way to work around this using
     the interface of the Uri library. *)
  decode "//abc/def";
  decode "/abc/def/";
  decode "/abc/def?";
  decode "/abc/def/?";
  decode "/abc?a";
  decode "/abc?a=b&c=d";
  decode "/abc%2F%26def?a=b&c=d%2B";
  decode "/abc/#foo";
  decode "/abc/?de=f#foo";
  [%expect {|
    "" ""
    "" ""
    "/" ""
    "/" ""
    "/abc/def" ""
    "/def" ""
    "/abc/def/" ""
    "/abc/def" ""
    "/abc/def/" ""
    "/abc" "a"
    "/abc" "a=b&c=d"
    "/abc%2F&def" "a=b&c=d%2B"
    "/abc/" ""
    "/abc/" "de=f" |}]
