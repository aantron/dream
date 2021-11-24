(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type 'a promise =
  'a Lwt.t

type reader =
  data:(buffer -> int -> int -> unit) ->
  close:(unit -> unit) ->
  flush:(unit -> unit) ->
  exn:(exn -> unit) ->
    unit

type stream = {
  next :
    data:(buffer -> int -> int -> unit) ->
    close:(unit -> unit) ->
    flush:(unit -> unit) ->
    exn:(exn -> unit) ->
      unit;

  (* TODO Needs continuation arguments. Writer feedback is ok, exception,
     closed. Ok should probably carry an int. *)
  (* TODO Continuation labels? *)
  (* TODO Really review these continuations. *)
  write :
    buffer -> int -> int ->
    (unit -> unit) -> (unit -> unit) -> (exn -> unit) ->
      unit;
  flush : (unit -> unit) -> (unit -> unit) -> (exn -> unit) -> unit;

  close : (unit -> unit) -> unit;
}

(* TODO Probably rename next throughout. *)
(* TODO Raise some exception when writes are attempted. *)
let read_only next =
  {
    next;
    write = (fun _buffer _offset _length _done _close _exn -> ());
    flush = (fun _done _close _exn -> ());
    close = (fun _done -> ());
  }

let empty =
  read_only (fun ~data:_ ~close ~flush:_ ~exn:_ -> close ())

(* TODO This shows the awkwardness in string-to-string body reading. *)
let string s =
  if String.length s = 0 then
    empty

  else begin
    let already_read = ref false in
    read_only begin fun ~data ~close ~flush:_ ~exn:_ ->
      if not !already_read then begin
        already_read := true;
        let length = String.length s in
        data (Bigstringaf.of_string ~off:0 ~len:length s) 0 length
      end
      else
        close ()
    end
  end

let next stream ~data ~close ~flush ~exn =
  stream.next ~data ~close ~flush ~exn

(* TODO Can probably save promise allocation if create a separate looping
   function. *)
let rec read stream =
  let promise, resolver = Lwt.wait () in

  begin
    stream.next
      ~data:(fun buffer offset length ->
        Bigstringaf.sub buffer ~off:offset ~len:length
        |> Bigstringaf.to_string
        |> Option.some
        |> Lwt.wakeup_later resolver)

      ~close:(fun () ->
        Lwt.wakeup_later resolver None)

      ~flush:(fun () ->
        let next_promise = read stream in
        Lwt.on_any
          next_promise
          (Lwt.wakeup_later resolver)
          (Lwt.wakeup_later_exn resolver))

      ~exn:(Lwt.wakeup_later_exn resolver)
  end;

  promise

let body stream =
  let promise, resolver = Lwt.wait () in
  let length = ref 0 in
  let buffer = ref (Bigstringaf.create 4096) in

  let rec loop () =
    stream.next
      ~data:(fun chunk offset chunk_length ->
        let new_length = !length + chunk_length in

        if new_length > Bigstringaf.length !buffer then begin
          let new_buffer = Bigstringaf.create (new_length * 2) in
          Bigstringaf.blit
            !buffer ~src_off:0 new_buffer ~dst_off:0 ~len:!length;
          buffer := new_buffer
        end;

        Bigstringaf.blit
          chunk ~src_off:offset !buffer ~dst_off:!length ~len:chunk_length;
        length := new_length;

        loop ())

      ~close:(fun () ->
        Bigstringaf.sub !buffer ~off:0 ~len:!length
        |> Bigstringaf.to_string
        |> Lwt.wakeup_later resolver)

      ~flush:loop

      (* TODO Make an effort to eagerly release the buffer? *)
      ~exn:(Lwt.wakeup_later_exn resolver)
  in
  loop ();

  promise

(* TODO Fix. This shouldn't return a promise. *)
let close stream =
  stream.close ignore;
  Lwt.return_unit

let write buffer offset length done_ close exn stream =
  stream.write buffer offset length done_ close exn

let flush done_ close exn stream =
  stream.flush done_ close exn

type pipe = {
  mutable state : [
    | `Idle
    | `Reader_waiting
    | `Writer_waiting
    | `Closed
  ];

  mutable read_data_callback : buffer -> int -> int -> unit;
  mutable read_close_callback : unit -> unit;
  mutable read_flush_callback : unit -> unit;
  mutable read_exn_callback : exn -> unit;

  mutable write_kind : [
    | `Data
    | `Flush
    | `Exn
  ];
  mutable write_buffer : buffer;
  mutable write_offset : int;
  mutable write_length : int;
  mutable write_done_callback : unit -> unit;
  mutable write_close_callback : unit -> unit;
  mutable write_exn_callback : exn -> unit;
}

let dummy_buffer =
  Bigstringaf.create 0

let dummy_read_data_callback _buffer _offset _length =
  ()

let clean_up_reader_fields pipe =
  pipe.read_data_callback <- dummy_read_data_callback;
  pipe.read_close_callback <- ignore;
  pipe.read_flush_callback <- ignore;
  pipe.read_exn_callback <- ignore

let clean_up_writer_fields pipe =
  pipe.write_buffer <- dummy_buffer;
  pipe.write_done_callback <- ignore;
  pipe.write_close_callback <- ignore;
  pipe.write_exn_callback <- ignore

let pipe () =
  let internal = {
    state = `Idle;

    read_data_callback = dummy_read_data_callback;
    read_close_callback = ignore;
    read_flush_callback = ignore;
    read_exn_callback = ignore;

    write_kind = `Data;
    write_buffer = dummy_buffer;
    write_offset = 0;
    write_length = 0;
    write_done_callback = ignore;
    write_close_callback = ignore;
    write_exn_callback = ignore;
  } in

  let next ~data ~close ~flush ~exn =
    match internal.state with
    | `Idle ->
      internal.state <- `Reader_waiting;
      internal.read_data_callback <- data;
      internal.read_close_callback <- close;
      internal.read_flush_callback <- flush;
      internal.read_exn_callback <- exn
    | `Reader_waiting ->
      raise (Failure "Stream read: the previous read has not completed")
    | `Writer_waiting ->
      internal.state <- `Idle;
      let write_done_callback = internal.write_done_callback in
      begin match internal.write_kind with
      | `Data ->
        let buffer = internal.write_buffer
        and offset = internal.write_offset
        and length = internal.write_length in
        clean_up_writer_fields internal;
        data buffer offset length;
        write_done_callback ();
      | `Flush ->
        clean_up_writer_fields internal;
        flush ();
        write_done_callback ();
      | `Exn ->
        (* TODO Real exception. *)
        clean_up_writer_fields internal;
        exn Exit;
        write_done_callback ();
      end
    | `Closed ->
      close ()
  in

  (* TODO Callbacks could definitely use labels, based on usage. *)
  let write buffer offset length done_ close exn =
    match internal.state with
    | `Idle ->
      internal.state <- `Writer_waiting;
      internal.write_kind <- `Data;
      internal.write_buffer <- buffer;
      internal.write_offset <- offset;
      internal.write_length <- length;
      internal.write_done_callback <- done_;
      internal.write_close_callback <- close;
      internal.write_exn_callback <- exn
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_data_callback = internal.read_data_callback in
      clean_up_reader_fields internal;
      read_data_callback buffer offset length;
      done_ ()
    | `Writer_waiting ->
      raise (Failure "Stream write: the previous write has not completed")
    | `Closed ->
      close ()
  in

  let close done_ =
    match internal.state with
    | `Idle ->
      internal.state <- `Closed;
      done_ ()
    | `Reader_waiting ->
      internal.state <- `Closed;
      let read_close_callback = internal.read_close_callback in
      clean_up_reader_fields internal;
      read_close_callback ();
      done_ ()
    | `Writer_waiting ->
      internal.state <- `Closed;
      let write_close_callback = internal.write_close_callback in
      clean_up_writer_fields internal;
      write_close_callback ();
      done_ ()
    | `Closed ->
      done_ ()
  in

  let flush done_ close exn =
    match internal.state with
    | `Idle ->
      internal.state <- `Writer_waiting;
      internal.write_kind <- `Flush;
      internal.write_done_callback <- done_;
      internal.write_close_callback <- close;
      internal.write_exn_callback <- exn
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_flush_callback = internal.read_flush_callback in
      clean_up_reader_fields internal;
      read_flush_callback ();
      done_ ()
    | `Writer_waiting ->
      raise (Failure "Stream flush: the previous write has not completed")
    | `Closed ->
      close ()
  in

  {next; write; flush; close}
