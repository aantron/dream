(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let show path =
  let components, query = Dream.test_parse_target path [@ocaml.warning "-3"] in

  components
  |> List.map (Printf.sprintf "\"%s\"")
  |> String.concat "; "
  |> Printf.printf "[%s]\n";

  if query <> "" then
    print_endline ("?" ^ query)

let%expect_test _ =
  show "";
  show "/";
  show "foo";
  show "/foo";
  show "/foo/bar";
  show "/foo/bar/";
  show "//foo";
  show "/foo//";
  show "/foo//bar";
  show "/foo///bar";
  [%expect {|
    []
    [""]
    ["foo"]
    ["foo"]
    ["foo"; "bar"]
    ["foo"; "bar"; ""]
    ["foo"]
    ["foo"; ""]
    ["foo"; "bar"]
    ["foo"; "bar"] |}]

let%expect_test _ =
  show "λ";
  show "/λ/λ/";
  [%expect {|
    ["λ"]
    ["λ"; "λ"; ""] |}]

let%expect_test _ =
  show "/%CE%BB/%CE%BB/";
  show "/%cE%Bb/%ce%bb/";
  show "/%c";
  show "/%c/";
  show "/%";
  show "/%/";
  show "/%30";
  [%expect {|
    ["λ"; "λ"; ""]
    ["λ"; "λ"; ""]
    ["%c"]
    ["%c"; ""]
    ["%"]
    ["%"; ""]
    ["0"] |}]

let%expect_test _ =
  show "/a?bcd";
  show "/a/b?cd";
  show "/?bcd";
  show "?bcd";
  show "/??bcd";
  show "/%30?bcd";
  show "/%3?bcd";
  show "/%?bcd";
  show "/a?bcd%30";
  [%expect {|
    ["a"]
    ?bcd
    ["a"; "b"]
    ?cd
    [""]
    ?bcd
    []
    ?bcd
    [""]
    ??bcd
    ["0"]
    ?bcd
    ["%3"]
    ?bcd
    ["%"]
    ?bcd
    ["a"]
    ?bcd%30 |}]
