open Soup

let () =
  let source = Sys.argv.(1) in
  let destination = Sys.argv.(2) in

  let soup = Soup.(read_file source |> parse) in

  let content = soup $ "div.odoc-content" in

  soup
  $ "nav.odoc-toc"
  |> Soup.prepend_child content;

  soup
  $$ "header.odoc-preamble > h1 ~ *"
  |> to_list
  |> List.rev
  |> List.iter (Soup.prepend_child content);

  Soup.(to_string content |> write_file destination)
