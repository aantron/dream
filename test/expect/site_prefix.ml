(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let internal_prefix =
  Dream.test_internal_prefix [@ocaml.warning "-3"]

let internal_path =
  Dream.test_internal_path [@ocaml.warning "-3"]

let show prefix target =

  Dream.request ~target ""
  |> Dream.test ~prefix begin fun request ->

    Printf.printf "Prefix: %S\n" (Dream.prefix request);

    internal_prefix request
    |> List.map (Printf.sprintf "%S")
    |> String.concat "; "
    |> Printf.printf "Raw: [%s]\n";

    internal_path request
    |> List.map (Printf.sprintf "%S")
    |> String.concat "; "
    |> Printf.printf "Path: [%s]\n";

    Dream.respond ""
  end
  |> fun response ->
    let status = Dream.status response in
    Printf.printf "Response: %i %s\n"
      (Dream.status_to_int status) (Dream.status_to_string status)



let%expect_test _ =
  show "" "/";
  show "/" "/";
  [%expect {|
    Prefix: "/"
    Raw: []
    Path: [""]
    Response: 200 OK
    Prefix: "/"
    Raw: []
    Path: [""]
    Response: 200 OK |}]

let%expect_test _ =
  show "/" "/abc/def";
  [%expect {|
    Prefix: "/"
    Raw: []
    Path: ["abc"; "def"]
    Response: 200 OK |}]

let%expect_test _ =
  show "/abc" "/abc/def";
  [%expect {|
    Prefix: "/abc"
    Raw: ["abc"]
    Path: ["def"]
    Response: 200 OK |}]

let%expect_test _ =
  show "/abc" "/def";
  [%expect {| Response: 502 Bad Gateway |}]

let%expect_test _ =
  show "/abc/def" "/abc";
  [%expect {| Response: 502 Bad Gateway |}]
