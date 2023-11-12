(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



open Soup.Infix

let if_expected expected test f =
  let actual = test () in
  if actual = expected then
    f ()
  else begin
    Soup.write_file "actual" actual;
    prerr_newline ();
    prerr_newline ();
    prerr_endline "Mismatch with expected initial HTML content.";
    prerr_newline ();
    prerr_endline
      "The Dream docs build rewrites HTML emitted by odoc to make it neater.";
    prerr_endline
      "Each rewritten tag has an expected initial content for sanity checking.";

    prerr_endline "The actual found content has been written to";
    prerr_newline ();
    prerr_endline ("  " ^ (Filename.concat (Sys.getcwd ()) "actual"));
    prerr_newline ();

    begin match String.split_on_char '\n' actual with
    | [] -> ()
    | first_line::_ ->
      prerr_endline "Hint:";
      prerr_newline ();
      prerr_endline ("  " ^ first_line);
      prerr_newline ()
    end;

    prerr_endline "Hint: make sure odoc 2.0.2 is installed.";
    prerr_endline
      "Other versions of odoc generate markup that doesn't match the expected.";
    prerr_newline ();

    Printf.ksprintf failwith "Mismatch"
  end

let add_backing_lines soup =
  let add_backing_line element =
    Soup.create_element ~class_:"backing" "div"
    |> Soup.prepend_child element
  in
  soup $$ "h2" |> Soup.iter add_backing_line;
  soup $$ "h3" |> Soup.iter add_backing_line;
  soup $$ ".spec[id]" |> Soup.iter add_backing_line;
  Soup.prepend_child
    (soup $ ".odoc-content") (Soup.create_element ~class_:"background" "div")
