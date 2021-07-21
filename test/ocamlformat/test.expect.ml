(* Failure: space still inserted near delimiters when not type-decl = sparse. *)
type t = {
  a : string;
  b : string;
  c : string;
}

let t =
  {
    a = "a_pretty_long_string_to_force_separate_line";
    b = "a_pretty_long_string_to_force_separate_line";
    c = "a_pretty_long_string_to_force_separate_line";
  }

type t =
  | A of int
  | B of string
  | C of unit

(* Failure: the bracket is set on the first line rather than having unifrom
   lines. *)
type t =
  [ `A of int
  | `B of string
  | `C of unit ]

let list = [a; b; c]

let list =
  [
    a_very_long_identifier_or_expression_one;
    a_very_long_identifier_or_expression_two;
    a_very_long_identifier_or_expression_three;
  ]

let bool =
  match true with
  | true -> false
  | false -> true

let () =
  match () with
  | () ->
    print_endline "foo";
    print_endline "bar"

(* Failure: begin...end indented strangely. *)
let () =
  match true with
  | true -> begin
    match () with
    | () ->
      print_endline "foo";
      print_endline "bar"
  end
  | () ->
    print_endline "foo";
    print_endline "bar"

let f = function
  | () ->
    print_endline "foo";
    print_endline "bar"

let () =
  if true then
    ()
  else
    ()
