(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type 'a promise =
  'a Lwt.t

type read =
  data:(buffer -> int -> int -> bool -> unit) ->
  close:(unit -> unit) ->
  flush:(unit -> unit) ->
  ping:(unit -> unit) ->
  pong:(unit -> unit) ->
    unit

type stream = {
  read : read;

  write :
    buffer -> int -> int -> bool ->
    ok:(unit -> unit) ->
    close:(unit -> unit) ->
      unit;

  flush :
    ok:(unit -> unit) ->
    close:(unit -> unit) ->
      unit;

  ping :
    ok:(unit -> unit) ->
    close:(unit -> unit) ->
      unit;

  pong :
    ok:(unit -> unit) ->
    close:(unit -> unit) ->
      unit;

  close : unit -> unit;
}

let read_only ~read ~close =
  {
    read;
    write =
      (fun _buffer _offset _length _fin ~ok:_ ~close:_ ->
        raise (Failure "write to a read-only stream"));
    flush =
      (fun ~ok:_ ~close:_ ->
        raise (Failure "flush of a read-only stream"));
    ping =
      (fun ~ok:_ ~close:_ ->
        raise (Failure "ping on a read-only stream"));
    pong =
      (fun ~ok:_ ~close:_ ->
        raise (Failure "pong on a read-only stream"));
    close;
  }

let empty =
  read_only
    ~read:(fun ~data:_ ~close ~flush:_ ~ping:_ ~pong:_ -> close ())
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
          0 length true
      | None ->
        close ()
    in

    let close () =
      string_ref := None;
    in

    read_only ~read ~close
  end

let read stream ~data ~close ~flush =
  stream.read ~data ~close ~flush

let read_convenience stream =
  let promise, resolver = Lwt.wait () in

  let rec loop () =
    stream.read
      ~data:(fun buffer offset length _fin ->
        Bigstringaf.sub buffer ~off:offset ~len:length
        |> Bigstringaf.to_string
        |> Option.some
        |> Lwt.wakeup_later resolver)

      ~close:(fun () ->
        Lwt.wakeup_later resolver None)

      ~flush:loop

      (* TODO This requires reordering the implementations and taking a harder
         look at all these functions.
         Upon a ping event, assume that we are on a read-write, duplex WebSocket
         stream, and send a pong. *)
      ~ping:loop

      ~pong:loop
  in
  loop ();

  promise

let read_until_close stream =
  let promise, resolver = Lwt.wait () in
  let length = ref 0 in
  let buffer = ref (Bigstringaf.create 4096) in

  let rec loop () =
    stream.read
      ~data:(fun chunk offset chunk_length _fin ->
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

      (* TODO As with the previous function, should respond to a ping with a
         pong. *)
      ~ping:loop

      ~pong:loop
  in
  loop ();

  promise

let close stream =
  stream.close ()

let write stream buffer offset length fin ~ok ~close =
  stream.write buffer offset length fin ~ok ~close

let flush stream ~ok ~close =
  stream.flush ~ok ~close

let ping stream ~ok ~close =
  stream.ping ~ok ~close

let pong stream ~ok ~close =
  stream.pong ~ok ~close

type pipe = {
  mutable state : [
    | `Idle
    | `Reader_waiting
    | `Writer_waiting
    | `Closed
  ];

  mutable read_data_callback : buffer -> int -> int -> bool -> unit;
  mutable read_close_callback : unit -> unit;
  mutable read_flush_callback : unit -> unit;
  mutable read_ping_callback : unit -> unit;
  mutable read_pong_callback : unit -> unit;

  mutable write_kind : [
    | `Data
    | `Flush
    | `Ping
    | `Pong
  ];
  mutable write_buffer : buffer;
  mutable write_offset : int;
  mutable write_length : int;
  mutable write_fin : bool;
  mutable write_ok_callback : unit -> unit;
  mutable write_close_callback : unit -> unit;
}

let dummy_buffer =
  Bigstringaf.create 0

let dummy_read_data_callback _buffer _offset _length _fin =
  () [@coverage off]

let clean_up_reader_fields pipe =
  pipe.read_data_callback <- dummy_read_data_callback;
  pipe.read_close_callback <- ignore;
  pipe.read_flush_callback <- ignore;
  pipe.read_ping_callback <- ignore;
  pipe.read_pong_callback <- ignore

let clean_up_writer_fields pipe =
  pipe.write_buffer <- dummy_buffer;
  pipe.write_ok_callback <- ignore;
  pipe.write_close_callback <- ignore

let pipe () =
  let internal = {
    state = `Idle;

    read_data_callback = dummy_read_data_callback;
    read_close_callback = ignore;
    read_flush_callback = ignore;
    read_ping_callback = ignore;
    read_pong_callback = ignore;

    write_kind = `Data;
    write_buffer = dummy_buffer;
    write_offset = 0;
    write_length = 0;
    write_fin = false;
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
    | `Reader_waiting ->
      raise (Failure "stream read: the previous read has not completed")
    | `Writer_waiting ->
      internal.state <- `Idle;
      let write_ok_callback = internal.write_ok_callback in
      let buffer = internal.write_buffer in
      clean_up_writer_fields internal;
      begin match internal.write_kind with
      | `Data ->
        data
          buffer internal.write_offset internal.write_length internal.write_fin
      | `Flush -> flush ()
      | `Ping -> ping ()
      | `Pong -> pong ()
      end;
      write_ok_callback ()
    | `Closed ->
      close ()
  in

  let write buffer offset length fin ~ok ~close =
    match internal.state with
    | `Idle ->
      internal.state <- `Writer_waiting;
      internal.write_kind <- `Data;
      internal.write_buffer <- buffer;
      internal.write_offset <- offset;
      internal.write_length <- length;
      internal.write_fin <- fin;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_data_callback = internal.read_data_callback in
      clean_up_reader_fields internal;
      read_data_callback buffer offset length fin;
      ok ()
    | `Writer_waiting ->
      raise (Failure "stream write: the previous write has not completed")
    | `Closed ->
      close ()
  in

  let close () =
    match internal.state with
    | `Idle ->
      internal.state <- `Closed
    | `Reader_waiting ->
      internal.state <- `Closed;
      let read_close_callback = internal.read_close_callback in
      clean_up_reader_fields internal;
      read_close_callback ()
    | `Writer_waiting ->
      internal.state <- `Closed;
      let write_close_callback = internal.write_close_callback in
      clean_up_writer_fields internal;
      write_close_callback ()
    | `Closed ->
      ()
  in

  let flush ~ok ~close =
    match internal.state with
    | `Idle ->
      internal.state <- `Writer_waiting;
      internal.write_kind <- `Flush;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_flush_callback = internal.read_flush_callback in
      clean_up_reader_fields internal;
      read_flush_callback ();
      ok ()
    | `Writer_waiting ->
      raise (Failure "stream flush: the previous write has not completed")
    | `Closed ->
      close ()
  in

  let ping ~ok ~close =
    match internal.state with
    | `Idle ->
      internal.state <- `Writer_waiting;
      internal.write_kind <- `Ping;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_ping_callback = internal.read_ping_callback in
      clean_up_reader_fields internal;
      read_ping_callback ();
      ok ()
    | `Writer_waiting ->
      raise (Failure "stream ping: the previous write has not completed")
    | `Closed ->
      close ()
  in

  let pong ~ok ~close =
    match internal.state with
    | `Idle ->
      internal.state <- `Writer_waiting;
      internal.write_kind <- `Pong;
      internal.write_ok_callback <- ok;
      internal.write_close_callback <- close
    | `Reader_waiting ->
      internal.state <- `Idle;
      let read_pong_callback = internal.read_pong_callback in
      clean_up_reader_fields internal;
      read_pong_callback ();
      ok ()
    | `Writer_waiting ->
      raise (Failure "stream pong: the previous write has not completed")
    | `Closed ->
      close ()
  in

  {read; write; flush; close; ping; pong}

let duplex ~read ~write ~close =
  {
    read = read.read;
    write = write.write;
    flush = write.flush;
    ping = write.ping;
    pong = write.pong;
    close;
  }

let stream ~read ~write ~flush ~ping ~pong ~close =
  {
    read;
    write;
    flush;
    ping;
    pong;
    close;
  }
