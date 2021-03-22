(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let parse string =
  string
  |> Dream.from_cookie
  |> List.map (fun (name, value) -> Printf.sprintf "%S=%S" name value)
  |> String.concat "; "
  |> Printf.printf "[%s]\n"

let%expect_test _ =
  parse "";
  parse "a";
  parse " a ";
  parse "a=b";
  parse " a = b ";
  parse "a=\"b\""; (* TODO This appears to parse incorrectly w.r.t RFC. *)
  parse "a=b;c=d";
  parse "a=b; c=d";
  parse "a=b ; c=d";
  parse "a=b;c";
  parse "a;c=d";
  [%expect {|
    []
    []
    []
    ["a"="b"]
    ["a"="b"]
    ["a"="\"b\""]
    ["c"="d"; "a"="b"]
    ["c"="d"; "a"="b"]
    ["c"="d"; "a"="b"]
    ["a"="b"]
    ["c"="d"] |}]
