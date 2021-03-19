(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* TODO Not at all efficient; can at least stream the file, maybe even cache. *)
(* TODO Also mind newlines on Windows. *)
(* TODO NOTE Using Lwt_io because it has a nice "read the whole thing"
   function. *)

let default_handler local_root path _ =
  let file = Filename.concat local_root path in
  Lwt.catch
    (fun () ->
      Lwt_io.(with_file ~mode:Input file)(fun channel ->
        Lwt_io.read channel
        |> Lwt.map Dream.response))
    (fun _exn -> Dream.respond ~status:`Not_Found "")

(* TODO Add ETag handling. *)
(* TODO Add automatic Content-Type handling. *)
(* TODO Add Content-Length handling? *)
(* TODO Support HEAD requests? *)

(* The path must:
   - Not have any .. or . components.
   - Not have any empty components. This should not be possible in Dream except
     for the last component, which, if empty, indicates a directory. We still
     check all components for robustness' sake.
   - Not be empty.
   - Not have the prefix /. Dream's path function generates a path with such a
     prefix, with the meaning that it is the site root. We remove that. The
     remaining path must not be an absolute path. *)
(* TODO On Windows, should we also check for \ and drive letters? *)
(* TODO Not an efficient implementation at the moment. *)
(* TODO It may be better to convert Dream's string list to a path first and then
   re-parse it, to avoid any potential issues with nested / due to any bugs that
   may be introduced. *)
let validate_path request =
  let path = Dream.internal_path request in

  let has_dot = List.exists ((=) Filename.current_dir_name) path in
  let has_dotdot = List.exists ((=) Filename.parent_dir_name) path in
  let has_empty = List.exists ((=) "") path in
  let is_empty = path = [] in

  if has_dot || has_dotdot || has_empty || is_empty then
    None

  else
    let path = String.concat Filename.dir_sep path in
    if Filename.is_relative path then
      Some path
    else
      None

let static ?(handler = default_handler) local_root = fun request ->

  if not @@ Dream.methods_equal (Dream.method_ request) `GET then
    Dream.respond ~status:`Method_Not_Allowed ""

  else
    match validate_path request with
    | None -> Dream.respond ~status:`Not_Found ""
    | Some path ->

      handler local_root path request
