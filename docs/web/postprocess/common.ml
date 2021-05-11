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
    Printf.ksprintf failwith "Mismatch; wrote %s"
      (Filename.concat (Sys.getcwd ()) "actual")
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
