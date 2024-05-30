(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Message = Dream_pure.Message



(* Used for converting the stream interface of [multipart_form] into the pull
   interface of Dream.

   [state] permits to dissociate the initial state made by
   [initial_multipart_state] and one which started to consume the body stream
   (see the call of [Upload.upload]). *)
type multipart_state = {
  mutable state_init : bool;
  mutable name : string option;
  mutable filename : string option;
  (* TODO Restore
  mutable stream : (< > * Multipart_form.Header.t * string Lwt_stream.t) Lwt_stream.t;
  *)
}

let initial_multipart_state () = {
  state_init = true;
  name = None;
  filename = None;
  (* TODO Restore
  stream = Lwt_stream.of_list [];
  *)
}

(* TODO Dump the value of the multipart state somehow? *)
let multipart_state_field : multipart_state Message.field =
  Message.new_field
    ~name:"dream.multipart"
    ()

let multipart_state request =
  match Message.field request multipart_state_field with
  | Some state -> state
  | None ->
    let state = initial_multipart_state () in
    Message.set_field request multipart_state_field state;
    state

let field_to_string (request : Message.request) field =
  let open Multipart_form in
  match field with
  | Field.Field (field_name, Field.Content_type, v) ->
    (field_name :> string), Content_type.to_string v
  | Field.Field (field_name, Field.Content_disposition, v) ->
    let state = multipart_state request in
    state.filename <- Content_disposition.filename v ;
    state.name <- Content_disposition.name v ;
    (field_name :> string), Content_disposition.to_string v
  | Field.Field (field_name, Field.Content_encoding, v) ->
    (field_name :> string), Content_encoding.to_string v
  | Field.Field (field_name, Field.Field, v) ->
    (field_name :> string), Unstrctrd.to_utf_8_string v

let log = Log.sub_log "dream.upload"

let upload_part (request : Message.request) =
  (* TODO Restore
  let state = multipart_state request in
  match%lwt Lwt_stream.peek state.stream with
  | None -> Lwt.return_none
  | Some (_uid, _header, stream) ->
    match%lwt Lwt_stream.get stream with
    | Some _ as v -> Lwt.return v
    | None ->
      log.debug (fun m -> m "End of the part.") ;
      let%lwt () = Lwt_stream.junk state.stream in
      (* XXX(dinosaure): delete the current part from the [stream]. *)
      Lwt.return_none
  *)
  ignore request;
  assert false

let identify _ = object end

type part = string option * string option * ((string * string) list)

let rec state (request : Message.request) =
  (* TODO Restore
  let state' = multipart_state request in
  let stream = state'.stream in
  match%lwt Lwt_stream.peek stream with
  | None -> let%lwt () = Lwt_stream.junk stream in Lwt.return_none
  | Some (_, headers, _stream) ->
    let headers =
      headers
      |> Multipart_form.Header.to_list
      |> List.map (field_to_string request)
    in
    let part =
      state'.name, state'.filename, headers in
    Lwt.return (Some part)
  *)
  ignore state;
  ignore request;
  assert false

and upload (request : Message.request) =
  (* TODO Restore
  let state' = multipart_state request in
  match state'.state_init with
  | false ->
    state request

  | true ->
    let content_type = match Message.header request "Content-Type" with
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
      let body =
        Lwt_stream.from (fun () ->
          Message.read (Message.server_stream request)) in
      let `Parse th, stream =
        Multipart_form_lwt.stream ~identify body content_type in
      Lwt.async (fun () -> let%lwt _ = th in Lwt.return_unit);
      state'.stream <- stream;
      state'.state_init <- false;
      state request
  *)
  ignore request;
  assert false

type multipart_form =
  (string * ((string option * string) list)) list
module Map = Map.Make (String)

let multipart ?(csrf=true) ~now request =
  (* TODO Restore
  let content_type = match Message.header request "Content-Type" with
    | Some content_type ->
      Result.to_option (Multipart_form.Content_type.of_string (content_type ^ "\r\n"))
    | None -> None in
  match content_type with
  | None -> Lwt.return `Wrong_content_type
  | Some content_type ->
    let body =
      Lwt_stream.from (fun () ->
        Message.read (Message.server_stream request)) in
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
      if csrf then
      Form.sort_and_check_form ~now
        (function
        | [None, value] -> value
        | _ -> "")
        parts request
      else
      let form = Form.sort parts in
      Lwt.return (`Ok form)
  *)
  ignore csrf;
  ignore now;
  ignore request;
  assert false
