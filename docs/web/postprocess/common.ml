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
  soup $$ ".spec[id]" |> Soup.iter add_backing_line
