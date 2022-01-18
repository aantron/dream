(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Formats = Dream_pure.Formats
module Message = Dream_pure.Message
module Method = Dream_pure.Method
module Router = Dream__server.Router
module Stream = Dream_pure.Stream



(* TODO Not at all efficient; can at least stream the file, maybe even cache. *)
(* TODO Also mind newlines on Windows. *)
(* TODO NOTE Using Lwt_io because it has a nice "read the whole thing"
   function. *)

let mime_lookup filename =
  let content_type =
    match Magic_mime.lookup filename with
    | "text/html" -> Formats.text_html
    | content_type -> content_type
  in
  ["Content-Type", content_type]

let from_filesystem local_root path _ =
  let file = Filename.concat local_root path in
  try
    Lwt_eio.Promise.await_lwt (
      Lwt_io.(with_file ~mode:Input file) (fun channel ->
          let%lwt content = Lwt_io.read channel in
          Message.response
            ~headers:(mime_lookup path) (Stream.string content) Stream.null
          |> Lwt.return)
    )
  with _exn ->
    Message.response ~status:`Not_Found Stream.empty Stream.null

(* TODO Add ETag handling. *)
(* TODO Add Content-Length handling? *)
(* TODO Support HEAD requests? *)

(* TODO On Windows, should we also check for \ and drive letters? *)
(* TODO Not an efficient implementation at the moment. *)
let validate_path request =
  let path = Router.path request in

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

  if not @@ Method.methods_equal (Message.method_ request) `GET then
    Message.response ~status:`Not_Found Stream.empty Stream.null

  else
    match validate_path request with
    | None ->
      Message.response ~status:`Not_Found Stream.empty Stream.null

    | Some path ->
      let response = loader local_root path request in
      if not (Message.has_header response "Content-Type") then begin
        match Message.status response with
        | `OK
        | `Non_Authoritative_Information
        | `No_Content
        | `Reset_Content
        | `Partial_Content ->
          Message.add_header response "Content-Type" (Magic_mime.lookup path)
        | _ ->
          ()
      end;
      response
