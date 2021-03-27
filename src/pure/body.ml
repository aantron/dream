(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type bigstring = Lwt_bytes.t

type bigstring_stream =
  (bigstring -> int -> int -> unit) ->
  (unit -> unit) ->
    unit

type string_stream =
  unit -> string option Lwt.t

type body = [
  | `Empty
  | `String of string
  | `Bigstring_stream of bigstring_stream
  | `String_stream of string_stream
]

type body_cell =
  body ref

let has_body body_cell =
  match !body_cell with
  | `Empty -> false
  | `String "" -> false
  | `String _ -> true
  | _ -> true

let buffer_body body_cell =
  match !body_cell with
  | `Empty
  | `String _ -> Lwt.return_unit

  | `Bigstring_stream stream ->
    let on_finished, finished = Lwt.wait () in

    let length = ref 0 in
    let buffer = ref (Lwt_bytes.create 4096) in

    let eof () =
      if !length = 0 then
        body_cell := `Empty
      else
        body_cell :=
          `String (Lwt_bytes.to_string (Lwt_bytes.proxy !buffer 0 !length));

      Lwt.wakeup_later finished ()
    in

    let rec data chunk offset chunk_length =
      let new_length = !length + chunk_length in

      if new_length > Lwt_bytes.length !buffer then begin
        let new_buffer = Lwt_bytes.create (new_length * 2) in
        Lwt_bytes.blit !buffer 0 new_buffer 0 !length;
        buffer := new_buffer
      end;

      Lwt_bytes.blit chunk offset !buffer !length chunk_length;
      length := new_length;

      stream data eof
    in

    stream data eof;

    on_finished

  | `String_stream stream ->
    let buffer = Buffer.create 4096 in

    let rec read () =
      match%lwt stream () with
      | None ->
        if Buffer.length buffer = 0 then
          body_cell := `Empty
        else
          body_cell := `String (Buffer.contents buffer);

        Lwt.return_unit

      | Some string ->
        Buffer.add_string buffer string;
        read ()
    in

    read ()

let body body_cell =
  buffer_body body_cell
  |> Lwt.map (fun () ->
    match !body_cell with
    | `Empty -> ""
    | `String body -> body
    | `Bigstring_stream _
    | `String_stream _ -> assert false)

let body_stream body_cell =
  match !body_cell with
  | `Empty ->
    Lwt.return_none

  | `String body ->
    body_cell := `Empty;
    Lwt.return (Some body)

  | `Bigstring_stream stream ->
    let promise, resolver = Lwt.wait () in

    let rec retrieve () =
      stream
        (fun data offset length ->
          if length = 0 then
            retrieve ()
          else
            Some (Lwt_bytes.to_string (Lwt_bytes.proxy data offset length))
            |> Lwt.wakeup_later resolver)
        (fun () ->
          body_cell := `Empty;
          Lwt.wakeup_later resolver None)
    in
    retrieve ();

    promise

  | `String_stream stream ->
    let rec retrieve () =
      let data_promise = stream () in
      match%lwt data_promise with
      | None ->
        body_cell := `Empty;
        Lwt.return_none
      | Some chunk ->
        if String.length chunk = 0 then
          retrieve ()
        else
          data_promise
    in
    retrieve ()

let body_stream_bigstring data eof body_cell =
  match !body_cell with
  | `Empty ->
    eof ()

  | `String body ->
    body_cell := `Empty;
    data (Lwt_bytes.of_string body) 0 (String.length body)

  (* TODO Is it possible to avoid the allocation by relying on the underlying
     stream to return EOF multiple times? If not, try partial application as a
     way to avoid allocation for a reader. *)
  | `Bigstring_stream stream ->
    let rec receive () =
      stream
        (fun chunk offset length ->
          if length = 0 then
            receive ()
          else
            data chunk offset length)
        (fun () ->
          body_cell := `Empty;
          eof ())
    in
    receive ()

  (* Optimizing this case is not as important, because `String_streams arise
     primarily in responses, but fast reads happen primarily on requests.
     However, this also depends on the HTTP layer using the right kind of read
     for the right kind of stream. *)
  | `String_stream stream ->
    let rec receive () =
      Lwt.on_any (stream ())
        (function
        | None ->
          body_cell := `Empty;
          eof ()
        | Some string ->
          if String.length string = 0 then
            receive ()
          else
            data (Lwt_bytes.of_string string) 0 (String.length string))
        raise
    in
    receive ()
