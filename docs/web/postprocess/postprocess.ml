open Soup

let () =
  let source = Sys.argv.(1) in
  let destination = Sys.argv.(2) in

  let soup = Soup.(read_file source |> parse) in

  let content = soup $ "div.odoc-content" in

  soup
  $ "nav.odoc-toc"
  |> Soup.prepend_child content;

  let preamble = Soup.create_element ~id:"pp-preamble" "div" in

  soup
  $$ "header.odoc-preamble > h1 ~ *"
  |> iter (Soup.append_child preamble);

  Soup.prepend_child content preamble;

  Soup.(to_string content |> write_file destination)
