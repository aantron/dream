(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type bigstring = Lwt_bytes.t

(* The stream representation can be replaced by a record with mutable fields for
   0-allocation streaming. *)
type writer =
  bigstring:(bigstring -> int -> int -> unit) ->
  string:(string -> int -> int -> unit) ->
  flush:(unit -> unit) ->
  close:(unit -> unit) ->
  exn:(exn -> unit) ->
    unit

type stream = [
  | `Idle
  | `Read of (writer -> unit)
  | `Write of writer * (exn -> unit)
]

let stream_read ~bigstring ~string ~flush ~close ~exn stream =
  match !stream with
  | `Idle ->
    stream := `Read (fun writer ->
      stream := `Idle;
      writer ~bigstring ~string ~flush ~close ~exn)
  | `Read _ ->
    exn (Failure ("Concurrent reads of same stream"))
  | `Write (writer, _) ->
    stream := `Idle;
    writer ~bigstring ~string ~flush ~close ~exn

let bigstring_writer chunk offset length k =
  fun ~bigstring ~string:_ ~flush:_ ~close:_ ~exn:_ ->
    bigstring chunk offset length;
    k ()

let string_writer chunk offset length k =
  fun ~bigstring:_ ~string ~flush:_ ~close:_ ~exn:_ ->
    string chunk offset length;
    k ()

let flush_writer k =
  fun ~bigstring:_ ~string:_ ~flush ~close:_ ~exn:_ ->
    flush ();
    k ()

let close_writer k =
  fun ~bigstring:_ ~string:_ ~flush:_ ~close ~exn:_ ->
    close ();
    k ()

let exn_writer the_exn k =
  fun ~bigstring:_ ~string:_ ~flush:_ ~close:_ ~exn ->
    exn the_exn;
    k ()

let stream_write writer stream k fail =
  match !stream with
  | `Idle ->
    stream := `Write (writer k, fail)
  | `Read reader ->
    reader (writer k)
  | `Write _ ->
    failwith "Concurrent writes to same stream"



(* TODO This probably can become a regular variant in the long term. *)
type body = [
  | `Empty
  | `Exn of exn
  | `String of string
  | `Stream of stream ref
]

type body_cell =
  body ref

let has_body body_cell =
  match !body_cell with
  | `Empty -> false
  | `String "" -> false
  | `String _ -> true
  | `Stream _ -> true
  | `Exn _ -> false
(* The purpose of storing exceptions is to prevent silent emission of false
   empty bodies. The exception itself is usually redundant. It would have been
   reported when it originally occurred. *)



let body : body_cell -> string Lwt.t = fun body_cell ->
  match !body_cell with
  | `Empty ->
    Lwt.return ""

  | `Exn exn ->
    Lwt.fail exn

  | `String body ->
    Lwt.return body

  | `Stream stream ->
    let promise, resolver = Lwt.wait () in

    let length = ref 0 in
    let buffer = ref (Lwt_bytes.create 4096) in

    let close () =
      let result = Lwt_bytes.to_string (Lwt_bytes.proxy !buffer 0 !length) in

      if !length = 0 then
        body_cell := `Empty
      else
        body_cell := `String result;

      Lwt.wakeup_later resolver result
    in

    let exn the_exn =
      body_cell := `Exn the_exn;
      Lwt.wakeup_later_exn resolver the_exn
    in

    let rec loop () =
      stream_read ~bigstring ~string ~flush ~close ~exn stream

    and bigstring chunk offset chunk_length =
      let new_length = !length + chunk_length in

      if new_length > Lwt_bytes.length !buffer then begin
        let new_buffer = Lwt_bytes.create (new_length * 2) in
        Lwt_bytes.blit !buffer 0 new_buffer 0 !length;
        buffer := new_buffer
      end;

      Lwt_bytes.blit chunk offset !buffer !length chunk_length;
      length := new_length;

      loop ()

    and string chunk offset chunk_length =
      let new_length = !length + chunk_length in

      if new_length > Lwt_bytes.length !buffer then begin
        let new_buffer = Lwt_bytes.create (new_length * 2) in
        Lwt_bytes.blit !buffer 0 new_buffer 0 !length;
        buffer := new_buffer
      end;

      Lwt_bytes.blit_from_bytes
        (Bytes.unsafe_of_string chunk) offset !buffer !length chunk_length;
      length := new_length;

      loop ()

    and flush () =
      loop ()

    in

    loop ();

    promise



let read : body_cell -> string option Lwt.t = fun body_cell ->
  match !body_cell with
  | `Empty ->
    Lwt.return_none

  | `Exn exn ->
    Lwt.fail exn

  | `String body ->
    body_cell := `Empty;
    Lwt.return (Some body)

  | `Stream stream ->
    let promise, resolver = Lwt.wait () in

    let close () =
      body_cell := `Empty;
      Lwt.wakeup_later resolver None
    in

    let exn the_exn =
      body_cell := `Exn the_exn;
      Lwt.wakeup_later_exn resolver the_exn
    in

    let rec loop () =
      stream_read ~bigstring ~string ~flush ~close ~exn stream

    and bigstring chunk offset length =
      Lwt.wakeup_later resolver
        (Some (Lwt_bytes.to_string (Lwt_bytes.proxy chunk offset length)))

    and string chunk offset length =
      let chunk =
        if offset = 0 && length = String.length chunk then
          chunk
        else
          String.sub chunk offset length
      in
      Lwt.wakeup_later resolver (Some chunk)

    and flush () =
      loop ()

    in

    loop ();

    promise



let next
    ~bigstring
    ?(string = fun _ _ _ -> ())
    ?(flush = ignore)
    ~close
    ~exn
    body_cell =

  match !body_cell with
  | `Empty ->
    close ()

  | `Exn the_exn ->
    exn the_exn

  | `String body ->
    body_cell := `Empty;
    string body 0 (String.length body)

  | `Stream stream ->
    stream_read ~bigstring ~string ~flush ~close ~exn stream



let write string body_cell =
  match !body_cell with
  | `Empty | `String _ ->
    failwith "Write into body that is not a stream; see Dream.with_stream"
  | `Exn exn ->
    Lwt.fail exn

  | `Stream stream ->
    let promise, resolver = Lwt.wait () in
    stream_write
      (string_writer string 0 (String.length string))
      stream
      (Lwt.wakeup_later resolver)
      (Lwt.wakeup_later_exn resolver);
    promise

let flush body_cell =
  match !body_cell with
  | `Empty | `String _ ->
    failwith "Flush of body that is not a stream; see Dream.with_stream"

  | `Exn exn ->
    Lwt.fail exn

  | `Stream stream ->
    let promise, resolver = Lwt.wait () in
    stream_write
      flush_writer
      stream
      (Lwt.wakeup_later resolver)
      (Lwt.wakeup_later_exn resolver);
    promise

let close_stream body_cell =
  match !body_cell with
  | `Empty | `String _ ->
    failwith "Close of body that is not a stream; see Dream.with_stream"

  | `Exn exn ->
    Lwt.fail exn

  | `Stream stream ->
    let promise, resolver = Lwt.wait () in
    stream_write
      close_writer
      stream
      (Lwt.wakeup_later resolver)
      (Lwt.wakeup_later_exn resolver);
    promise

let write_bigstring bigstring offset length body_cell =
  match !body_cell with
  | `Empty | `String _ ->
    failwith "Write into body that is not a stream; see Dream.with_stream"
  | `Exn exn ->
    Lwt.fail exn

  | `Stream stream ->
    let promise, resolver = Lwt.wait () in
    stream_write
      (bigstring_writer bigstring offset length)
      stream
      (Lwt.wakeup_later resolver)
      (Lwt.wakeup_later_exn resolver);
    promise



let report exn body_cell =
  match !body_cell with
  | `Exn _ ->
    ()

  | `Empty | `String _ ->
    body_cell := `Exn exn

  | `Stream stream ->
    body_cell := `Exn exn;
    match !stream with
    | `Write (_, report) -> report exn
    | _ -> ()

(* TODO Review GC-friendliness. *)
