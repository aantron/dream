let if_expected expected test f =
  let actual = test () in
  if actual = expected then
    f ()
  else begin
    Soup.write_file "actual" actual;
    Printf.ksprintf failwith "Mismatch; wrote %s"
      (Filename.concat (Sys.getcwd ()) "actual")
  end
