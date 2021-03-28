(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



type upload_result = [
  | `File of string * string * string
  | `Field of string * string
  | `Done
]

(* TODO multipart-form-data returns 4K-long chunks, so these should be
   represented as substreams. *)
type multipart_state =
  | Initial
  | Awaiting of upload_result Lwt.u
  | Files of unit Lwt.u
  | Fields of (string * string) list

(* TODO If keeping this design, give this variable a name for the debugger. *)
let multipart_state =
  Dream.new_local ()

let begin_upload request =
  request
  |> Dream.with_local multipart_state (ref Initial)

(* TODO How does this respond to various Content-Types? *)
(* TODO Actually handle missing Content-Type header, etc. *)
(* TODO multipart-form-data appears to raise Invalid_argument internally, and
   perhaps other exceptions, on malformed input. This seems to be a defect. *)
(* TODO multipart-form-data appears to return the ordinary fields of the form
   last. This means that the application will receive all data before it has a
   chance to check validity, especially of any included CSRF token. That seems
   like a defect. *)
(* TODO multipart-form-data appears to choke on parentheses in filenames. *)
let upload request =
  let state = Dream.local multipart_state request |> Option.get in
  match !state with
  | Initial ->

    let body = Lwt_stream.from (fun () -> Dream.read request) in
    let content_type = Dream.header "Content-Type" request |> Option.get in

    let callback ~name ~filename data =
      let push_result =
        match !state with
        | Awaiting push_result -> push_result
        | _ -> assert false (* TODO A better error. *)
      in
      let on_continue, continue = Lwt.wait () in
      state := Files continue;
      Lwt.wakeup_later push_result (`File (name, filename, data));
      on_continue
    in

    let on_result, push_result = Lwt.wait () in
    state := Awaiting push_result;

    Lwt.async (fun () ->
      let%lwt fields =
        Multipart_form_data.parse
          ~stream:body
          ~content_type
          ~callback in

      let push_result =
        match !state with
        | Awaiting push_result -> push_result
        | _ -> assert false (* TODO A better error. *)
      in

      begin match fields with
      | [] -> Lwt.wakeup_later push_result `Done
      | field::more ->
        state := Fields more;
        Lwt.wakeup_later push_result (`Field field)
      end;

      Lwt.return_unit);

    on_result

  | Files continue ->
    let on_result, push_result = Lwt.wait () in
    state := Awaiting push_result;
    Lwt.wakeup_later continue ();
    on_result

  | Fields fields ->
    begin match fields with
    | [] -> Lwt.return `Done
    | field::more ->
      state := Fields more;
      Lwt.return (`Field field)
    end

  | Awaiting _ ->
    assert false
