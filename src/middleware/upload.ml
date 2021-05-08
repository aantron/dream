(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Calascibetta Romain *)



module Dream = Dream__pure.Inmost

let field_to_string (request : Dream.request) field =
  let open Multipart_form in
  match field with
  | Field.Field (field_name, Field.Content_type, v) ->
    Lwt.return (`Field ((field_name :> string), Content_type.to_string v))
  | Field.Field (field_name, Field.Content_disposition, v) ->
    request.specific.upload.filename <- Content_disposition.filename v ;
    request.specific.upload.name <- Content_disposition.name v ;
    Lwt.return (`Field ((field_name :> string), Content_disposition.to_string v))
  | Field.Field (field_name, Field.Content_encoding, v) ->
    Lwt.return (`Field ((field_name :> string), Content_encoding.to_string v))
  | Field.Field (field_name, Field.Field, v) ->
    Lwt.return (`Field ((field_name :> string), Unstrctrd.to_utf_8_string v))

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

(* XXX(dinosaure): the state machine is such as:

                           .-->--[state]-->--.
   [`Init] -[upload]-> [`Header]         [`Part]
                           '--<--[state]--<--'

   The first call to [upload] sets the state to [`Header] if we can extract a
   [Content-Type]. Then, from the [`Header] state, we emit one by one fields of
   the current decoding part. When all of these fields (including
   [Content-Disposition]) are consumed, we set the state to [`Part]. The user
   should call then [upload_part]. We re-loop into [state] with [`Header] to
   emit:

   - [`Done] if we don't have parts anymore
   - fields of the new part.

   By this way, the common use should be:
   {[
     # upload request ;;
     - [> `Field of string * string ] = `Field ("content-type", ...)
     # upload request ;;
     - [> `Field of string * string ] = `Field ("content-disposition", ...)
     # upload request ;;
     - [> `Part of string option * string option ]
     = `Part (Some "file", Some "image.png")
     # upload_part request ;;
     - string option = Some ...
     # upload_part request ;;
     - string option = None
     # upload request ;;
     - [> `Field of string * string ] = `Field ("content-type", ...)
     ...
     # upload request ;;
     - [> `Done ]
   ]}
*)

type state = [ `Header | `Part ]

let rec state (request : Dream.request) v =
  let stream = request.specific.upload.stream in
  match%lwt Lwt_stream.peek stream with
  | None -> let%lwt () = Lwt_stream.junk stream in Lwt.return `Done
  | Some (_, header, _stream) -> match v with
    | `Part ->
      log.debug (fun m -> m "Start to upload a new part.") ;
      (* XXX(dinosaure): new part. *)
      request.specific.upload.state <- `Header ;
      request.specific.upload.nth <- 0 ;
      request.specific.upload.name <- None ;
      request.specific.upload.filename <- None ;
      state request `Header
    | `Header ->
      let header = Multipart_form.Header.to_list header in
      let n = request.specific.upload.nth in
      if n < List.length header
      then ( log.debug (fun m -> m "Show the field %d." n)
           ; request.specific.upload.nth <- n + 1
           ; field_to_string request (List.nth header n) )
      else
        ( request.specific.upload.state <- `Part
        ; Lwt.return (`Part (request.specific.upload.name, request.specific.upload.filename)) )

and upload (request : Dream.request) =
  match request.specific.upload.state with
  | #state as v -> state request v
  | `Init ->
    let content_type = match Dream.header "content-type" request with
      | Some content_type ->
        Result.to_option (Multipart_form.Content_type.of_string (content_type ^ "\r\n"))
      | None -> None in
    match content_type with
    | None ->
      log.error (fun m -> m "The upload request does not contain a Content-Type.") ;
      Lwt.return `Wrong_content_type
    | Some content_type ->
      log.debug (fun m -> m "Start to analyze the upload request.") ;
      let body = Lwt_stream.from (fun () -> Dream.read request) in
      let `Parse th, stream = Multipart_form_lwt.stream ~identify body content_type in
      Lwt.async (fun () -> let%lwt _ = th in Lwt.return_unit) ;
      request.specific.upload.stream <- stream ;
      request.specific.upload.state <- `Header ;
      state request `Header

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
