(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO Needed? *)
module Bigstring = Bigarray.Array1

type bigstring =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigstring.t

(* TODO LATER For now, Dream is following a simple model. The http server layer
   DOES NOT allocate a buffer, but stores a reading function in the request.
   When the body is actually needed by something in the web app, it is read to
   completion. *)
(* TODO LATER This exposes the framework to large request attacks. *)

(* Not every request will need body reading, so don't allocate a buffer for each
   requesst - only allocate it upon request. *)
type buffered_body = [
  | `Empty
  | `String of string
  | `Bigstring of bigstring
]
(* TODO Get rid of Bigstring constructor. *)

type body = [
  | buffered_body
  | `Bigstring_stream of (bigstring option -> unit) -> unit
  | `Reading of buffered_body Lwt.t
]

type body_cell = body ref

let has_body body_cell =
  match !body_cell with
  | `Empty -> false
  | `String "" -> false
  | `String _ -> true
  | `Bigstring body -> Bigstring.size_in_bytes body > 0
  | _ -> true

let new_bigstring length =
  Bigstring.create Bigarray.char Bigarray.c_layout length

(* TODO LATER This is the preliminary reader implementation described in
   comments above. It should eventually be replaced by a 0-copy reader, but that
   will likely require a much more low-level web server integration. *)
let buffer_body body_cell : buffered_body Lwt.t =
  match !body_cell with
  | #buffered_body as body -> Lwt.return body
  | `Reading on_finished -> on_finished

  | `Bigstring_stream stream ->
    let on_finished, finished = Lwt.wait () in
    body_cell := `Reading on_finished;

    let rec read body length =
      stream begin function
      | None ->
        let body =
          if Bigstring.size_in_bytes body = 0 then
            `Empty
          else
          `Bigstring (Bigstring.sub body 0 length)
        in
        body_cell := body;
        Lwt.wakeup_later finished body

      | Some chunk ->
        let chunk_length = Bigstring.size_in_bytes chunk in
        let new_length = length + chunk_length in
        let body =
          if new_length <= Bigstring.size_in_bytes body then
            body
          else
            let new_body = new_bigstring (new_length * 2) in
            Bigstring.blit
              (Bigstring.sub body 0 length) (Bigstring.sub new_body 0 length);
            new_body
        in
        Bigstring.blit chunk (Bigstring.sub body length chunk_length);
        read body new_length
      end
    in

    read (new_bigstring 4096) 0;

    on_finished

let body body_cell =
  buffer_body body_cell
  |> Lwt.map begin function
    | `Empty -> ""
    | `String body -> body
    | `Bigstring body -> Lwt_bytes.to_string body
  end

(* TODO LATER There need to be buffering and unbuffering version of this. The
   HTTP server needs a version that does not buffer. The app, by default,
   should get buffering. *)
let buffered_body_stream body =
  let sent = ref false in

  fun k ->
    if !sent then
      k None
    else begin
      sent := true;
      match body with
      | `Empty -> k None
      | `String body -> k (Some (Lwt_bytes.of_string body))
      | `Bigstring body -> k (Some body)
    end

let body_stream body_cell =
  match !body_cell with
  | #buffered_body as body -> buffered_body_stream body
  | `Bigstring_stream stream -> stream
  | `Reading on_finished ->
    fun k ->
      Lwt.on_success on_finished (fun body -> buffered_body_stream body k)
