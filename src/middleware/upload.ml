(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let chunk_callback (state : Dream.multipart_state) ~name ~filename data =
  let on_continue, continue = Lwt.wait () in
  state.continue <- continue;

  begin match state.event_listener with
  | Some event_listener ->
    state.event_listener <- None;
    state.last_field_name <- Some name;
    state.last_file_name <- Some filename;
    state.buffered_chunk <- Some data;
    Lwt.wakeup_later event_listener (`File (name, filename))

  | None ->
    match state.chunk_listener with
    | Some chunk_listener ->
      state.chunk_listener <- None;
      if state.last_field_name = Some name &&
         state.last_file_name = Some filename then
        Lwt.wakeup_later chunk_listener (Some data)
      else begin
        state.last_field_name <- Some name;
        state.last_file_name <- Some filename;
        state.buffered_chunk <- Some data;
        state.next_file <- true;
        Lwt.wakeup_later chunk_listener None
      end

    | None ->
      failwith
        "Dream.upload: received chunk, but Dream.upload_file was not called"
  end;

  on_continue

let upload_file (request : Dream.request) =
  let state = request.specific.upload in

  match state.buffered_chunk with
  | Some chunk ->
    if state.next_file then
      Lwt.return_none
    else begin
      state.buffered_chunk <- None;
      Lwt.return (Some chunk)
    end

  | None ->
    let on_chunk, push_chunk = Lwt.wait () in
    state.chunk_listener <- Some push_chunk;
    Lwt.wakeup_later state.continue ();
    on_chunk

let content_type = "multipart/form-data"

let check_content_type received =
  String.length received >= String.length content_type &&
  String.sub received 0 (String.length content_type) = content_type

(* TODO multipart-form-data appears to raise Invalid_argument internally, and
   perhaps other exceptions, on malformed input. This seems to be a defect. *)
(* TODO multipart-form-data appears to return the ordinary fields of the form
   last. This means that the application will receive all data before it has a
   chance to check validity, especially of any included CSRF token. That seems
   like a defect. *)
(* TODO multipart-form-data appears to choke on parentheses in filenames. *)
let rec upload (request : Dream.request) =
  let state = request.specific.upload in
  match state.initial with
  | true ->
    state.initial <- false;

    begin match Dream.header "Content-Type" request with
    | Some content_type when check_content_type content_type ->

      Lwt.async begin fun () ->
        (* While waiting for the fields, Multipart_form_data will first receive
           all file chunks. *)
        let%lwt fields =
          Multipart_form_data.parse
            ~stream:(Lwt_stream.from (fun () -> Dream.read request))
            ~content_type
            ~callback:(chunk_callback state) in

        (* All chunks have been received at this point. Now, process the form
           fields. *)
        let remaining_fields = ref fields in
        let next_field () =
          match !remaining_fields with
          | [] -> None
          | field::more ->
            remaining_fields := more;
            Some field
        in

        state.fields <- true;
        state.field <- (fun () -> Lwt.return (next_field ()));

        begin match state.event_listener with
        | Some event_listener ->
          begin match next_field () with
          | Some field -> Lwt.wakeup_later event_listener (`Field field)
          | None -> Lwt.wakeup_later event_listener `Done
          end
        | None ->
          match state.chunk_listener with
          | Some chunk_listener ->
            Lwt.wakeup_later chunk_listener None
          | None ->
            ()
        end;

        Lwt.return_unit
      end;

      upload request

    | _ ->
      Lwt.return `Wrong_content_type
    end

  | false as _not_initial ->
    let s = state in
    match s.buffered_chunk, s.last_field_name, s.last_file_name with
    | Some _, Some name, Some filename ->
      state.next_file <- false;
      Lwt.return (`File (name, filename))

    | _ ->
      if not state.fields then begin
        let on_event, push_event = Lwt.wait () in
        state.event_listener <- Some push_event;
        Lwt.wakeup_later state.continue ();
        on_event
      end
      else begin
        match%lwt state.field () with
        | None -> Lwt.return `Done
        | Some field -> Lwt.return (`Field field)
      end

type part = [
  | `Files of (string * string) list
  | `Value of string
]

let log =
  Log.sub_log "dream.upload"

let multipart request =

  let rec upload_parts files fields =
    match%lwt upload request with
    | `Wrong_content_type ->
      log.warning (fun log -> log ~request
        "Content-Type not 'multipart/form-data'");
      Lwt.return `Wrong_content_type

    | `File (name, filename) ->
      let buffer = Buffer.create 4096 in
      let rec upload_file_parts () =
        match%lwt upload_file request with
        | None ->
          Lwt.return (Buffer.contents buffer)
        | Some chunk ->
          Buffer.add_string buffer chunk;
          upload_file_parts ()
      in
      let%lwt content = upload_file_parts () in
      upload_parts ((name, filename, content)::files) fields

    | `Field (name, value) ->
      upload_parts files ((name, value)::fields)

    | `Done ->
      (* Group the files by field name. This also reverses them into the
         correct order as a side effect. *)
      let files_by_field = Hashtbl.create 16 in
      files |> List.iter (fun (name, filename, content) ->
        let files =
          match Hashtbl.find_opt files_by_field name with
          | None -> []
          | Some files -> files
        in
        Hashtbl.replace files_by_field name ((filename, content)::files));
      let file_parts =
        Hashtbl.fold
          (fun name files file_parts -> (name, `Files files)::file_parts)
          files_by_field
          []
      in

      (* Tag the ordinary fields. *)
      let field_parts =
        fields |> List.map (fun (name, value) -> name, `Value value) in

      (* Concatenate it all into a form, and pass through the ordinary form
         sorter and CSRF checker. *)
      let to_value = function
        | `Files _ -> failwith "File field has same name as CSRF token field"
        | `Value string -> string
      in
      Form.sort_and_check_form to_value (file_parts @ field_parts) request
  in
  upload_parts [] []
