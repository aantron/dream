(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type read =
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  flush:(unit -> unit) ->
  ping:(buffer -> int -> int -> unit) ->
  pong:(buffer -> int -> int -> unit) ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
    unit

type write =
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit

type reader = {
  read : read;
  close : int -> unit;
  abort : exn -> unit;
}

type writer = {
  data : buffer -> int -> int -> bool -> bool -> write;
  flush : write;
  ping : buffer -> int -> int -> write;
  pong : buffer -> int -> int -> write;
  close : int -> unit;
  abort : exn -> unit;
}

type stream = {
  reader : reader;
  writer : writer;
}

let stream reader writer =
  {reader; writer}

let no_reader = {
  read =
    (fun ~data:_ ~flush:_ ~ping:_ ~pong:_ ~close:_ ~exn:_ ->
      raise (Failure "read from a non-readable stream"));
  close =
    ignore;
  abort =
    ignore;
}

let no_writer = {
  data =
    (fun _buffer _offset _length _binary _fin ~close:_ ~exn:_ _ok ->
      raise (Failure "write to a read-only stream"));
  flush =
    (fun ~close:_ ~exn:_ _ok ->
      raise (Failure "flush of a read-only stream"));
  ping =
    (fun _buffer _offset _length ~close:_ ~exn:_ _ok ->
      raise (Failure "ping on a read-only stream"));
  pong =
    (fun _buffer _offset _length ~close:_ ~exn:_ _ok ->
      raise (Failure "pong on a read-only stream"));
  close =
    ignore;
  abort =
    ignore;
}

let reader ~read ~close ~abort = {
  read;
  close;
  abort;
}

let null = {
  reader = no_reader;
  writer = no_writer;
}

let empty_reader =
  reader
    ~read:(fun ~data:_ ~flush:_ ~ping:_ ~pong:_ ~close ~exn:_ -> close 1000)
    ~close:ignore
    ~abort:ignore

let empty = {
  reader = empty_reader;
  writer = no_writer;
}

(* TODO This shows the awkwardness in string-to-string body reading. *)
let string_reader the_string =
  (* Storing the string in a ref here so that we can "lose" it eagerly once
     the stream is closed, making the memory available to the GC. *)
  let string_ref = ref (Some the_string) in
  let exn_ref = ref None in

  let read ~data ~flush:_ ~ping:_ ~pong:_ ~close ~exn =
    match !exn_ref with
    | Some the_exn ->
      exn the_exn
    | None ->
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
    string_ref := None
  in

  let abort exn =
    string_ref := None;
    exn_ref := Some exn
  in

  reader ~read ~close ~abort

let string the_string =
  if String.length the_string = 0 then
    empty
  else
    {
      reader = string_reader the_string;
      writer = no_writer;
    }

let read stream ~data ~flush ~ping ~pong ~close ~exn =
  stream.reader.read ~data ~flush ~ping ~pong ~close ~exn

let close stream code =
  stream.reader.close code;
  stream.writer.close code

let abort stream exn =
  stream.reader.abort exn;
  stream.writer.abort exn

let write stream buffer offset length binary fin ~close ~exn ok =
  stream.writer.data buffer offset length binary fin ~close ~exn ok

let flush stream ~close ~exn ok =
  stream.writer.flush ~close ~exn ok

let ping stream buffer offset length ~close ~exn ok =
  stream.writer.ping buffer offset length ~close ~exn ok

let pong stream buffer offset length ~close ~exn ok =
  stream.writer.pong buffer offset length ~close ~exn ok

(* TODO Restore "double write" checks by adding a state showing that a writer
   is already queued, and add tests for this. This should be done after ping
   and pong get their separate queues. *)
type pipe = {
  mutable state : [
    | `Idle
    | `Reader_waiting
    | `Closed of int
    | `Aborted of exn
  ];

  mutable read_data_callback : buffer -> int -> int -> bool -> bool -> unit;
  mutable read_flush_callback : unit -> unit;
  mutable read_ping_callback : buffer -> int -> int -> unit;
  mutable read_pong_callback : buffer -> int -> int -> unit;
  mutable read_close_callback : int -> unit;
  mutable read_abort_callback : exn -> unit;

  mutable write_ok_callback : unit -> unit;
  mutable write_close_callback : int -> unit;
  mutable write_abort_callback : exn -> unit;
}

let dummy_read_data_callback _buffer _offset _length _binary _fin =
  () [@coverage off]

let dummy_ping_pong_callback _buffer _offset _length =
  () [@coverage off]

let clean_up_reader_fields pipe =
  pipe.read_data_callback <- dummy_read_data_callback;
  pipe.read_flush_callback <- ignore;
  pipe.read_ping_callback <- dummy_ping_pong_callback;
  pipe.read_pong_callback <- dummy_ping_pong_callback;
  pipe.read_close_callback <- ignore;
  pipe.read_abort_callback <- ignore

let clean_up_writer_fields pipe =
  pipe.write_ok_callback <- ignore;
  pipe.write_close_callback <- ignore;
  pipe.write_abort_callback <- ignore

let pipe () =
  let internal = {
    state = `Idle;

    read_data_callback = dummy_read_data_callback;
    read_flush_callback = ignore;
    read_ping_callback = dummy_ping_pong_callback;
    read_pong_callback = dummy_ping_pong_callback;
    read_close_callback = ignore;
    read_abort_callback = ignore;

    write_ok_callback = ignore;
    write_close_callback = ignore;
    write_abort_callback = ignore;
  } in

  let read ~data ~flush ~ping ~pong ~close ~exn =
    match internal.state with
    | `Idle ->
      internal.state <- `Reader_waiting;
      internal.read_data_callback <- data;
      internal.read_flush_callback <- flush;
      internal.read_ping_callback <- ping;
      internal.read_pong_callback <- pong;
      internal.read_close_callback <- close;
      internal.read_abort_callback <- exn;
      let write_ok_callback = internal.write_ok_callback in
      clean_up_writer_fields internal;
      write_ok_callback ()
    | `Reader_waiting ->
      raise (Failure "stream read: the previous read has not completed")
    | `Closed code ->
      close code
    | `Aborted the_exn ->
      exn the_exn
  in

  let rec data buffer offset length binary fin ~close ~exn ok =
    match internal.state with
    | `Idle ->
      internal.write_ok_callback <- (fun () ->
        data buffer offset length binary fin ~close ~exn ok);
      internal.write_close_callback <- close;
      internal.write_abort_callback <- exn
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_data_callback = internal.read_data_callback in
      clean_up_reader_fields internal;
      read_data_callback buffer offset length binary fin;
      ok ()
    | `Closed code ->
      close code
    | `Aborted the_exn ->
      exn the_exn
  in

  let rec flush ~close ~exn ok =
    match internal.state with
    | `Idle ->
      internal.write_ok_callback <- (fun () ->
        flush ~close ~exn ok);
      internal.write_close_callback <- close;
      internal.write_abort_callback <- exn
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_flush_callback = internal.read_flush_callback in
      clean_up_reader_fields internal;
      read_flush_callback ();
      ok ()
    | `Closed code ->
      close code
    | `Aborted the_exn ->
      exn the_exn
  in

  let rec ping buffer offset length ~close ~exn ok =
    match internal.state with
    | `Idle ->
      internal.write_ok_callback <- (fun () ->
        ping buffer offset length ~close ~exn ok);
      internal.write_close_callback <- close;
      internal.write_abort_callback <- exn
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_ping_callback = internal.read_ping_callback in
      clean_up_reader_fields internal;
      read_ping_callback buffer offset length;
      ok ()
    | `Closed code ->
      close code
    | `Aborted the_exn ->
      exn the_exn
  in

  let rec pong buffer offset length ~close ~exn ok =
    match internal.state with
    | `Idle ->
      internal.write_ok_callback <- (fun () ->
        pong buffer offset length ~close ~exn ok);
      internal.write_close_callback <- close;
      internal.write_abort_callback <- exn
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_pong_callback = internal.read_pong_callback in
      clean_up_reader_fields internal;
      read_pong_callback buffer offset length;
      ok ()
    | `Closed code ->
      close code
    | `Aborted the_exn ->
      exn the_exn
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
    | `Aborted _the_exn ->
      ()
  in

  let abort exn =
    match internal.state with
    | `Idle ->
      internal.state <- `Aborted exn;
      let write_abort_callback = internal.write_abort_callback in
      clean_up_writer_fields internal;
      write_abort_callback exn
    | `Reader_waiting ->
      internal.state <- `Aborted exn;
      let read_abort_callback = internal.read_abort_callback in
      clean_up_reader_fields internal;
      read_abort_callback exn
    | `Closed _code ->
      ()
    | `Aborted _the_exn ->
      ()
  in

  let reader = {
    read;
    close;
    abort;
  }
  and writer = {
    data;
    flush;
    ping;
    pong;
    close;
    abort;
  } in

  (reader, writer)

let forward (reader : reader) stream =
  let rec loop () =
    reader.read
      ~data:(fun buffer offset length binary fin ->
        stream.writer.data
          buffer offset length
          binary fin
          ~close:reader.close ~exn:reader.abort
          loop)
      ~flush:(fun () ->
        stream.writer.flush ~close:reader.close ~exn:reader.abort loop)
      ~ping:(fun buffer offset length ->
        stream.writer.ping
          buffer offset length ~close:reader.close ~exn:reader.abort loop)
      ~pong:(fun buffer offset length ->
        stream.writer.pong
          buffer offset length ~close:reader.close ~exn:reader.abort loop)
      ~close:stream.writer.close
      ~exn:stream.writer.abort
  in
  loop ()

let read_convenience stream =
  (* TODO Restore
  let promise, resolver = Lwt.wait () in
  let close _code = Lwt.wakeup_later resolver None in
  let abort exn = Lwt.wakeup_later_exn resolver exn in

  let rec loop () =
    stream.reader.read
      ~data:(fun buffer offset length _binary _fin ->
        Bigstringaf.sub buffer ~off:offset ~len:length
        |> Bigstringaf.to_string
        |> Option.some
        |> Lwt.wakeup_later resolver)

      ~flush:loop

      ~ping:(fun buffer offset length ->
        stream.writer.pong buffer offset length ~close ~exn:abort loop)

      ~pong:(fun _buffer _offset _length ->
        loop ())

      ~close

      ~exn:abort
  in
  loop ();

  promise
  *)
  ignore stream;
  assert false

(* TODO It's probably best to protect "wakeups" of the promise to prevent
   Invalid_argument from Lwt. *)
let read_until_close stream =
  let promise, resolver = Eio.Promise.create () in
  let length = ref 0 in
  let buffer = ref (Bigstringaf.create 4096) in
  let close _code =
    Bigstringaf.sub !buffer ~off:0 ~len:!length
    |> Bigstringaf.to_string
    |> Eio.Promise.resolve_ok resolver
  in
  let abort exn = Eio.Promise.resolve_error resolver exn in

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

      ~flush:loop

      ~ping:(fun buffer offset length ->
        stream.writer.pong buffer offset length ~close ~exn:abort loop)

      ~pong:(fun _buffer _offset _length ->
        loop ())

      ~close

      ~exn:abort
  in
  loop ();

  promise
