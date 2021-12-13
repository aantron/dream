(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure



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
    let prefix = Dream.site_prefix request in
    match match_site_prefix prefix (Dream.path request) with
    | None ->
      (* TODO Streams. *)
      let client_stream = Dream.Stream.(stream empty no_writer)
      and server_stream = Dream.Stream.(stream no_reader no_writer) in
      Dream.response ~status:`Bad_Gateway client_stream server_stream
      |> Lwt.return
    | Some path ->
      (* TODO This doesn't need to be recomputed on each request - can cache the
         result in the app. *)
      let prefix_reversed = List.rev prefix in
      request
      |> Dream.with_prefix prefix_reversed
      |> Dream.with_path path
      |> next_handler
