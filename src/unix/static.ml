(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure



(* TODO Not at all efficient; can at least stream the file, maybe even cache. *)
(* TODO Also mind newlines on Windows. *)
(* TODO NOTE Using Lwt_io because it has a nice "read the whole thing"
   function. *)

let mime_lookup filename =
  let content_type =
    match Magic_mime.lookup filename with
    | "text/html" -> Dream_pure.Formats.text_html
    | content_type -> content_type
  in
  ["Content-Type", content_type]

let from_filesystem local_root path _ =
  let file = Filename.concat local_root path in
  Lwt.catch
    (fun () ->
      Lwt_io.(with_file ~mode:Input file) (fun channel ->
        let%lwt content = Lwt_io.read channel in
        (* TODO Can use some pre-allocated streams or helpers here and below. *)
        let client_stream = Dream.Stream.(stream (string content) no_writer)
        and server_stream = Dream.Stream.(stream no_reader no_writer) in
        Dream.response ~headers:(mime_lookup path) client_stream server_stream
        |> Lwt.return))
    (fun _exn ->
      (* TODO Improve the two-stream code using some helper. *)
      let client_stream = Dream.Stream.(stream empty no_writer)
      and server_stream = Dream.Stream.(stream no_reader no_writer) in
      Dream.response ~status:`Not_Found client_stream server_stream
      |> Lwt.return)

(* TODO Add ETag handling. *)
(* TODO Add Content-Length handling? *)
(* TODO Support HEAD requests? *)

(* TODO On Windows, should we also check for \ and drive letters? *)
(* TODO Not an efficient implementation at the moment. *)
let validate_path request =
  let path = Dream.path request in

  let has_slash component = String.contains component '/' in
  let has_backslash component = String.contains component '\\' in
  let has_slash = List.exists has_slash path in
  let has_backslash = List.exists has_backslash path in
  let has_dot = List.exists ((=) Filename.current_dir_name) path in
  let has_dotdot = List.exists ((=) Filename.parent_dir_name) path in
  let has_empty = List.exists ((=) "") path in
  let is_empty = path = [] in

  if has_slash ||
     has_backslash ||
     has_dot ||
     has_dotdot ||
     has_empty ||
     is_empty then
    None

  else
    let path = String.concat Filename.dir_sep path in
    if Filename.is_relative path then
      Some path
    else
      None

let static ?(loader = from_filesystem) local_root = fun request ->

  if not @@ Dream.methods_equal (Dream.method_ request) `GET then
    (* TODO Simplify this code and reduce allocations. *)
    let client_stream = Dream.Stream.(stream empty no_writer)
    and server_stream = Dream.Stream.(stream no_reader no_writer) in
    Dream.response ~status:`Not_Found client_stream server_stream
    |> Lwt.return

  else
    match validate_path request with
    | None ->
      (* TODO Improve with helpers. *)
      let client_stream = Dream.Stream.(stream empty no_writer)
      and server_stream = Dream.Stream.(stream no_reader no_writer) in
      Dream.response ~status:`Not_Found client_stream server_stream
      |> Lwt.return

    | Some path ->

      let%lwt response = loader local_root path request in

      let response =
        if Dream.has_header "Content-Type" response then
          response
        else
          match Dream.status response with
          | `OK
          | `Non_Authoritative_Information
          | `No_Content
          | `Reset_Content
          | `Partial_Content ->
            Dream.add_header "Content-Type" (Magic_mime.lookup path) response
          | _ ->
            response
      in

      Lwt.return response
