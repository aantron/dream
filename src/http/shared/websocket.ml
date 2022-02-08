(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2022 Anton Bachin *)



module Stream = Dream_pure.Stream



let websocket_handler stream socket =
  (* Queue of received frames. There doesn't appear to be a nice way to achieve
     backpressure with the current API of websocket/af, so that will have to be
     added later. The user-facing API of Dream does support backpressure. *)
  let frames, push_frame = Lwt_stream.create () in
  let message_is_binary = ref `Binary in

  (* Frame reader called by websocket/af on each frame received. There is no
     good way to truly throttle this, hence this frame reader pushes frame
     objects into the above frame queue for the reader to take from later. See
     https://github.com/anmonteiro/websocketaf/issues/34. *)
  let frame ~opcode ~is_fin ~len:_ payload =
    match opcode with
    | `Connection_close ->
      push_frame (Some (`Close, payload))
    | `Ping ->
      push_frame (Some (`Ping, payload))
    | `Pong ->
      push_frame (Some (`Pong, payload))
    | `Other _ ->
      push_frame (Some (`Other, payload))
    | `Text ->
      message_is_binary := `Text;
      push_frame (Some (`Data (`Text, is_fin), payload))
    | `Binary ->
      message_is_binary := `Binary;
      push_frame (Some (`Data (`Binary, is_fin), payload))
    | `Continuation ->
      push_frame (Some (`Data (!message_is_binary, is_fin), payload))
  in

  let eof () =
    push_frame None in

  (* The reader retrieves the next frame. If it is a data frame, it keeps a
     reference to the payload across multiple reader calls, until the payload is
     exhausted. *)
  let closed = ref false in
  let close_code = ref 1005 in
  let current_payload = ref None in

  (* Used to convert the separate on_eof payload reading callback into a FIN bit
     on the last chunk read. See
     https://github.com/anmonteiro/websocketaf/issues/35. *)
  let last_chunk = ref None in
  (* TODO Review per-chunk allocations, including current_payload contents. *)

  (* For control frames, the payload can be at most 125 bytes long. We assume
     that the first chunk will contain the whole payload, and discard any other
     chunks that may be reported by websocket/af. *)
  let first_chunk_received = ref false in
  let first_chunk = ref Bigstringaf.empty in
  let first_chunk_offset = ref 0 in
  let first_chunk_length = ref 0 in
  let rec drain_payload payload continuation =
    Websocketaf.Payload.schedule_read
      payload
      ~on_read:(fun buffer ~off ~len ->
        if not !first_chunk_received then begin
          first_chunk := buffer;
          first_chunk_offset := off;
          first_chunk_length := len;
          first_chunk_received := true
        end
        else
          (* TODO How to integrate this thing with logging? *)
          (* websocket_log.warning (fun log ->
            log "Received fragmented control frame"); *)
          ();
        drain_payload payload continuation)
      ~on_eof:(fun () ->
        let payload = !first_chunk in
        let offset = !first_chunk_offset in
        let length = !first_chunk_length in
        first_chunk_received := false;
        first_chunk := Bigstringaf.empty;
        first_chunk_offset := 0;
        first_chunk_length := 0;
        continuation payload offset length)
  in

  (* TODO Can this be canceled by a user's close? i.e. will that eventually
     cause a call to eof above? *)
  let rec read ~data ~flush ~ping ~pong ~close ~exn =
    if !closed then
      close !close_code
    else
      match !current_payload with
      | None ->
        Lwt.on_success (Lwt_stream.get frames) begin function
        | None ->
          if not !closed then begin
            closed := true;
            close_code := 1005
          end;
          Websocketaf.Wsd.close socket;
          close !close_code
        | Some (`Close, payload) ->
          drain_payload payload @@ fun buffer offset length ->
          let code =
            if length < 2 then
              1005
            else
              let high_byte = Char.code buffer.{offset}
              and low_byte = Char.code buffer.{offset + 1} in
              high_byte lsl 8 lor low_byte
          in
          if not !closed then
            close_code := code;
          close !close_code
        | Some (`Ping, payload) ->
          drain_payload payload @@
          ping
        | Some (`Pong, payload) ->
          drain_payload payload @@
          pong
        | Some (`Other, payload) ->
          drain_payload payload @@ fun _buffer _offset length ->
          ignore length; (* TODO log instead *)
          (* websocket_log.warning (fun log ->
            log "Unknown frame type with length %i" length); *)
          read ~data ~flush ~ping ~pong ~close ~exn
        | Some (`Data properties, payload) ->
          current_payload := Some (properties, payload);
          read ~data ~flush ~ping ~pong ~close ~exn
        end
      | Some ((binary, fin), payload) ->
        Websocketaf.Payload.schedule_read
          payload
          ~on_read:(fun buffer ~off ~len ->
            match !last_chunk with
            | None ->
              last_chunk := Some (buffer, off, len);
              read ~data ~flush ~ping ~pong ~close ~exn
            | Some (last_buffer, last_offset, last_length) ->
              last_chunk := Some (buffer, off, len);
              let binary = binary = `Binary in
              data last_buffer last_offset last_length binary false)
          ~on_eof:(fun () ->
            current_payload := None;
            match !last_chunk with
            | None ->
              read ~data ~flush ~ping ~pong ~close ~exn
            | Some (last_buffer, last_offset, last_length) ->
              last_chunk := None;
              let binary = binary = `Binary in
              data last_buffer last_offset last_length binary fin)
  in

  let bytes_since_flush = ref 0 in

  let flush ~close ok =
    bytes_since_flush := 0;
    if !closed then
      close !close_code
    else
      Websocketaf.Wsd.flushed socket ok
  in

  let close code =
    if not !closed then begin
      (* TODO Really need to work out the "close handshake" and how it is
         exposed in the Stream API. *)
      (* closed := true; *)
      Websocketaf.Wsd.close ~code:(`Other code) socket
    end
  in

  let abort _exn = close 1005 in

  let reader = Stream.reader ~read ~close ~abort in
  Stream.forward reader stream;

  let rec outgoing_loop () =
    Stream.read
      stream
      ~data:(fun buffer offset length binary _fin ->
        (* Until https://github.com/anmonteiro/websocketaf/issues/33. *)
        (* if not fin then
          websocket_log.error (fun log ->
            log "Non-FIN frames not yet supported"); *)
        let kind = if binary then `Binary else `Text in
        if !closed then
          close !close_code
        else begin
          Websocketaf.Wsd.schedule socket ~kind buffer ~off:offset ~len:length;
          bytes_since_flush := !bytes_since_flush + length;
          if !bytes_since_flush >= 4096 then
            flush ~close outgoing_loop
          else
            outgoing_loop ()
        end)
      ~flush:(fun () -> flush ~close outgoing_loop)
      ~ping:(fun _buffer _offset length ->
        if length > 125 then
          raise (Failure "Ping payload cannot exceed 125 bytes");
        (* See https://github.com/anmonteiro/websocketaf/issues/36. *)
        (* if length > 0 then
          websocket_log.warning (fun log ->
            log "Ping with non-empty payload not yet supported"); *)
        if !closed then
          close !close_code
        else begin
          Websocketaf.Wsd.send_ping socket;
          outgoing_loop ()
        end)
      ~pong:(fun _buffer _offset length ->
        (* TODO Is there any way for the peer to send a ping payload with more
           than 125 bytes, forcing a too-large pong and an exception? *)
        if length > 125 then
          raise (Failure "Pong payload cannot exceed 125 bytes");
        (* See https://github.com/anmonteiro/websocketaf/issues/36. *)
        (* if length > 0 then
          websocket_log.warning (fun log ->
            log "Pong with non-empty payload not yet supported"); *)
        if !closed then
          close !close_code
        else begin
          Websocketaf.Wsd.send_pong socket;
          outgoing_loop ()
        end)
      ~close
      ~exn:abort
  in
  outgoing_loop ();

  Websocketaf.Server_connection.{frame; eof}

  (* TODO The equality between server and client input handlers is not
     exposed in the websocketaf API.
     https://github.com/anmonteiro/websocketaf/issues/39. *)
let client_websocket_handler :
    Stream.stream -> Websocketaf.Wsd.t ->
      Websocketaf.Client_connection.input_handlers =
  Obj.magic websocket_handler
