(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost
module Formats = Dream_pure.Formats
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
      (* TODO Streams. *)
      let client_stream = Stream.(stream empty no_writer)
      and server_stream = Stream.(stream no_reader no_writer) in
      Dream.response ~status:`Bad_Gateway client_stream server_stream
      |> Lwt.return
    | Some path ->
      (* TODO This doesn't need to be recomputed on each request - can cache the
         result in the app. *)
      Router.set_prefix request (List.rev prefix);
      Router.set_path request path;
      next_handler request
