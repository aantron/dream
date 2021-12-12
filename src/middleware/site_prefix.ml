(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost



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
let chop_site_prefix next_handler request =
    let prefix = (Dream.app request).site_prefix in
    match match_site_prefix prefix (Dream.path request) with
    | None ->
      Dream.empty `Bad_Gateway
    | Some path ->
      (* TODO This doesn't need to be recomputed on each request - can cache the
         result in the app. *)
      let prefix_reversed = List.rev prefix in
      request
      |> Dream.with_prefix prefix_reversed
      |> Dream.with_path path
      |> next_handler
