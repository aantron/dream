(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost

let field_to_string (request : Dream.request) field =
  let open Multipart_form in
  match field with
  | Field.Field (field_name, Field.Content_type, v) ->
    (field_name :> string), Content_type.to_string v
  | Field.Field (field_name, Field.Content_disposition, v) ->
    request.specific.upload.filename <- Content_disposition.filename v ;
    request.specific.upload.name <- Content_disposition.name v ;
    (field_name :> string), Content_disposition.to_string v
  | Field.Field (field_name, Field.Content_encoding, v) ->
    (field_name :> string), Content_encoding.to_string v
  | Field.Field (field_name, Field.Field, v) ->
    (field_name :> string), Unstrctrd.to_utf_8_string v

let log = Log.sub_log "dream.upload"

let upload_part (request : Dream.request) =
  match%lwt Lwt_stream.peek request.specific.upload.stream with
  | None -> Lwt.return_none
  | Some (_uid, _header, stream) ->
    match%lwt Lwt_stream.get stream with
    | Some _ as v -> Lwt.return v
    | None ->
      log.debug (fun m -> m "End of the part.") ;
      let%lwt () = Lwt_stream.junk request.specific.upload.stream in
      (* XXX(dinosaure): delete the current part from the [stream]. *)
      Lwt.return_none

let identify _ = object end

type part = string option * string option * ((string * string) list)

let rec state (request : Dream.request) =
  let stream = request.specific.upload.stream in
  match%lwt Lwt_stream.peek stream with
  | None -> let%lwt () = Lwt_stream.junk stream in Lwt.return_none
  | Some (_, headers, _stream) ->
    let headers =
      headers
      |> Multipart_form.Header.to_list
      |> List.map (field_to_string request)
    in
    let part =
      request.specific.upload.name, request.specific.upload.filename, headers in
    Lwt.return (Some part)

and upload (request : Dream.request) =
  match request.specific.upload.state_init with
  | false ->
    state request

  | true ->
    let content_type = match Dream.header "content-type" request with
    | Some content_type ->
      Result.to_option
        (Multipart_form.Content_type.of_string (content_type ^ "\r\n"))
    | None ->
      None
    in

    match content_type with
    | None ->
      let message =
        "The request does not have 'Content-Type: multipart/form_data; ...'" in
      log.error (fun log -> log "%s" message);
      failwith message

    | Some content_type ->
      let body = Lwt_stream.from (fun () -> Dream.read request) in
      let `Parse th, stream =
        Multipart_form_lwt.stream ~identify body content_type in
      Lwt.async (fun () -> let%lwt _ = th in Lwt.return_unit);
      request.specific.upload.stream <- stream;
      request.specific.upload.state_init <- false;
      state request

type multipart_form =
  (string * ((string option * string) list)) list
module Map = Map.Make (String)

let multipart request =
  let content_type = match Dream.header "content-type" request with
    | Some content_type ->
      Result.to_option (Multipart_form.Content_type.of_string (content_type ^ "\r\n"))
    | None -> None in
  match content_type with
  | None -> Lwt.return `Wrong_content_type
  | Some content_type ->
    let body = Lwt_stream.from (fun () -> Dream.read request) in
    match%lwt Multipart_form_lwt.of_stream_to_list body content_type with
    | Error (`Msg _err) ->
      Lwt.return `Wrong_content_type (* XXX(dinosaure): better error? *)
    | Ok (tree, assoc) ->
      let open Multipart_form in
      let tree = flatten tree in
      let fold acc { Multipart_form.header; body= uid; } =
        let contents = List.assoc uid assoc in
        let content_disposition = Header.content_disposition header in
        let filename = Option.bind content_disposition Content_disposition.filename in
        match Option.bind content_disposition Content_disposition.name with
        | None -> acc
        | Some name ->
          let vs =
            match Map.find_opt name acc with
            | Some vs -> vs
            | None -> []
          in
          Map.add name ((filename, contents)::vs) acc
      in
      let parts =
        List.fold_left fold Map.empty tree
        |> Map.bindings
        |> List.map (fun (name, values) ->
          match values with
          | [Some "", ""] -> name, []
          | _ -> name, List.rev values)
      in
      Form.sort_and_check_form
        (function
        | [None, value] -> value
        | _ -> "")
        parts request
