(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Formats = Dream_pure.Formats
module Message = Dream_pure.Message
module Stream = Dream_pure.Stream



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
let with_site_prefix prefix =
  let prefix =
    prefix
    |> Formats.from_path
    |> Formats.drop_trailing_slash
  in
  fun next_handler request ->
    match match_site_prefix prefix (Router.path request) with
    | None ->
      Message.response ~status:`Bad_Gateway Stream.empty Stream.null
    | Some path ->
      (* TODO This doesn't need to be recomputed on each request - can cache the
         result in the app. *)
      Router.set_prefix request (List.rev prefix);
      Router.set_path request path;
      next_handler request
