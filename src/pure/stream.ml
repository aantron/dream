(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type 'a promise =
  'a Lwt.t

type read =
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  close:(int -> unit) ->
  flush:(unit -> unit) ->
  ping:(buffer -> int -> int -> unit) ->
  pong:(buffer -> int -> int -> unit) ->
    unit

type write =
  close:(int -> unit) ->
  (unit -> unit) ->
    unit

type reader = {
  read : read;
  close : int -> unit;
}

type writer = {
  ready : write;
  write : buffer -> int -> int -> bool -> bool -> write;
  flush : write;
  ping : buffer -> int -> int -> write;
  pong : buffer -> int -> int -> write;
  close : int -> unit;
}

type stream = {
  reader : reader;
  writer : writer;
}

let stream reader writer =
  {reader; writer}

let no_reader = {
  read =
    (fun ~data:_ ~close:_ ~flush:_ ~ping:_ ~pong:_ ->
      raise (Failure "read from a non-readable stream"));
  close =
    ignore;
}

let no_writer = {
  ready =
    (fun ~close:_ _ok ->
      raise (Failure "ready called on a read-only stream"));
  write =
    (fun _buffer _offset _length _binary _fin ~close:_ _ok ->
      raise (Failure "write to a read-only stream"));
  flush =
    (fun ~close:_ _ok ->
      raise (Failure "flush of a read-only stream"));
  ping =
    (fun _buffer _offset _length ~close:_ _ok ->
      raise (Failure "ping on a read-only stream"));
  pong =
    (fun _buffer _offset _length ~close:_ _ok ->
      raise (Failure "pong on a read-only stream"));
  close =
    ignore;
}

let reader ~read ~close =
  {read; close}

let writer ~ready ~write ~flush ~ping ~pong ~close =
  {ready; write; flush; ping; pong; close}

let empty =
  reader
    ~read:(fun ~data:_ ~close ~flush:_ ~ping:_ ~pong:_ -> close 1000)
    ~close:ignore

(* TODO This shows the awkwardness in string-to-string body reading. *)
let string the_string =
  if String.length the_string = 0 then
    empty
  else begin
    (* Storing the string in a ref here so that we can "lose" it eagerly once
       the stream is closed, making the memory available to the GC. *)
    let string_ref = ref (Some the_string) in

    let read ~data ~close ~flush:_ ~ping:_ ~pong:_ =
      match !string_ref with
      | Some stored_string ->
        string_ref := None;
        let length = String.length stored_string in
        data
          (Bigstringaf.of_string ~off:0 ~len:length stored_string)
          0 length true true
      | None ->
        close 1000
    in

    let close _code =
      string_ref := None;
    in

    reader ~read ~close
  end

let read stream ~data ~close ~flush =
  stream.reader.read ~data ~close ~flush

let close stream code =
  stream.reader.close code;
  stream.writer.close code

(* TODO Test this somehow with guards for early writing on a pipe. *)
let ready stream ~close ok =
  stream.writer.ready ~close ok

let write stream buffer offset length binary fin ~close ok =
  stream.writer.write buffer offset length binary fin ~close ok

let flush stream ~close ok =
  stream.writer.flush ~close ok

let ping stream buffer offset length ~close ok =
  stream.writer.ping buffer offset length ~close ok

let pong stream buffer offset length ~close ok =
  stream.writer.pong buffer offset length ~close ok

type pipe = {
  mutable state : [
    | `Idle
    | `Reader_waiting
    | `Closed of int
  ];

  mutable read_data_callback : buffer -> int -> int -> bool -> bool -> unit;
  mutable read_close_callback : int -> unit;
  mutable read_flush_callback : unit -> unit;
  mutable read_ping_callback : buffer -> int -> int -> unit;
  mutable read_pong_callback : buffer -> int -> int -> unit;

  mutable write_ok_callback : unit -> unit;
  mutable write_close_callback : int -> unit;
}

let dummy_read_data_callback _buffer _offset _length _binary _fin =
  () [@coverage off]

let dummy_ping_pong_callback _buffer _offset _length =
  () [@coverage off]

let clean_up_reader_fields pipe =
  pipe.read_data_callback <- dummy_read_data_callback;
  pipe.read_close_callback <- ignore;
  pipe.read_flush_callback <- ignore;
  pipe.read_ping_callback <- dummy_ping_pong_callback;
  pipe.read_pong_callback <- dummy_ping_pong_callback

let clean_up_writer_fields pipe =
  pipe.write_ok_callback <- ignore;
  pipe.write_close_callback <- ignore

let pipe () =
  let internal = {
    state = `Idle;

    read_data_callback = dummy_read_data_callback;
    read_close_callback = ignore;
    read_flush_callback = ignore;
    read_ping_callback = dummy_ping_pong_callback;
    read_pong_callback = dummy_ping_pong_callback;

    write_ok_callback = ignore;
    write_close_callback = ignore;
  } in

  let read ~data ~close ~flush ~ping ~pong =
    match internal.state with
    | `Idle ->
      internal.state <- `Reader_waiting;
      internal.read_data_callback <- data;
      internal.read_close_callback <- close;
      internal.read_flush_callback <- flush;
      internal.read_ping_callback <- ping;
      internal.read_pong_callback <- pong;
      let write_ok_callback = internal.write_ok_callback in
      clean_up_writer_fields internal;
      write_ok_callback ()
    | `Reader_waiting ->
      raise (Failure "stream read: the previous read has not completed")
    | `Closed code ->
      close code
  in

  let ready ~close ok =
    match internal.state with
    | `Idle ->
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close
    | `Reader_waiting ->
      ok ()
    | `Closed code ->
      close code
  in

  let write buffer offset length binary fin ~close ok =
    match internal.state with
    | `Idle ->
      raise (Failure "stream write: the stream is not ready")
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_data_callback = internal.read_data_callback in
      clean_up_reader_fields internal;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close;
      read_data_callback buffer offset length binary fin;
    | `Closed code ->
      close code
  in

  let close code =
    match internal.state with
    | `Idle ->
      internal.state <- `Closed code;
      let write_close_callback = internal.write_close_callback in
      clean_up_writer_fields internal;
      write_close_callback code
    | `Reader_waiting ->
      internal.state <- `Closed code;
      let read_close_callback = internal.read_close_callback in
      clean_up_reader_fields internal;
      read_close_callback code
    | `Closed _code ->
      ()
  in

  let flush ~close ok =
    match internal.state with
    | `Idle ->
      raise (Failure "stream flush: the previous write has not completed")
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_flush_callback = internal.read_flush_callback in
      clean_up_reader_fields internal;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close;
      read_flush_callback ()
    | `Closed code ->
      close code
  in

  let ping buffer offset length ~close ok =
    match internal.state with
    | `Idle ->
      raise (Failure "stream ping: the previous write has not completed")
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_ping_callback = internal.read_ping_callback in
      clean_up_reader_fields internal;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close;
      read_ping_callback buffer offset length
    | `Closed code ->
      close code
  in

  let pong buffer offset length ~close ok =
    match internal.state with
    | `Idle ->
      raise (Failure "stream pong: the previous write has not completed")
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_pong_callback = internal.read_pong_callback in
      clean_up_reader_fields internal;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close;
      read_pong_callback buffer offset length
    | `Closed code ->
      close code
  in

  let reader = {
    read;
    close;
  }
  and writer = {
    ready;
    write;
    flush;
    ping;
    pong;
    close;
  } in

  (reader, writer)

let read_convenience stream =
  let promise, resolver = Lwt.wait () in
  let close _code = Lwt.wakeup_later resolver None in

  let rec loop () =
    stream.reader.read
      ~data:(fun buffer offset length _binary _fin ->
        Bigstringaf.sub buffer ~off:offset ~len:length
        |> Bigstringaf.to_string
        |> Option.some
        |> Lwt.wakeup_later resolver)

      ~close

      ~flush:loop

      ~ping:(fun buffer offset length ->
        stream.writer.pong buffer offset length ~close loop)

      ~pong:(fun _buffer _offset _length ->
        ())
  in
  loop ();

  promise

let read_until_close stream =
  let promise, resolver = Lwt.wait () in
  let length = ref 0 in
  let buffer = ref (Bigstringaf.create 4096) in
  let close _code =
    Bigstringaf.sub !buffer ~off:0 ~len:!length
    |> Bigstringaf.to_string
    |> Lwt.wakeup_later resolver
  in

  let rec loop () =
    stream.reader.read
      ~data:(fun chunk offset chunk_length _binary _fin ->
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

      ~close

      ~flush:loop

      ~ping:(fun buffer offset length ->
        stream.writer.pong buffer offset length ~close loop)

      ~pong:(fun _buffer _offset _length ->
        ())
  in
  loop ();

  promise
