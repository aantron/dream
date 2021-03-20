(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let rec match_site_prefix prefix path =
  match prefix, path with
  | prefix_crumb::prefix, path_crumb::path ->
    if path_crumb = prefix_crumb then
      match_site_prefix prefix path
    else
      None
  | [], path ->
    Some path
  | _ ->
    None



(* TODO The path and prefix representations and accessors need a cleanup. *)
(* TODO May want to factor out the URL parsing later. *)
let chop_site_prefix prefix =
  let prefix =
    prefix
    |> Dream__pure.Formats.parse_target
    |> fst
    |> Dream__pure.Formats.trim_empty_trailing_component
  in

  let prefix_reversed = List.rev prefix in

  fun next_handler request ->
    match match_site_prefix prefix (Dream.internal_path request) with
    | None ->
      Dream.respond ~status:`Bad_Gateway ""
    | Some path ->
      request
      |> Dream.with_prefix prefix_reversed
      |> Dream.with_path path
      |> next_handler
