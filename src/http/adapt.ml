(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Stream = Dream_pure.Stream
module Message = Dream_pure.Message



let address_to_string : Unix.sockaddr -> string = function
  | ADDR_UNIX path -> path
  | ADDR_INET (address, port) ->
    Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port



(* TODO Write a test simulating client exit during SSE; this was killing the
   server at some point. *)
let forward_body_general
    (response : Message.response)
    (_write_string : ?off:int -> ?len:int -> string -> unit)
    (write_buffer : ?off:int -> ?len:int -> Stream.buffer -> unit)
    http_flush
    close =

  let abort _exn = close 1000 in

  let bytes_since_flush = ref 0 in

  let rec send () =
    Message.client_stream response
    |> fun stream ->
      Stream.read
        stream
        ~data
        ~flush
        ~ping
        ~pong
        ~close
        ~exn:abort

  and data chunk off len _binary _fin =
    write_buffer ~off ~len chunk;
    bytes_since_flush := !bytes_since_flush + len;
    if !bytes_since_flush >= 4096 then begin
      bytes_since_flush := 0;
      http_flush send
    end
    else
      send ()

  and flush () =
    bytes_since_flush := 0;
    http_flush send

  and ping _buffer _offset _length =
    send ()

  and pong _buffer _offset _length =
    send ()

  in

  send ()

let forward_body
    (response : Message.response)
    (body : Httpaf.Body.Writer.t) =

  forward_body_general
    response
    (Httpaf.Body.Writer.write_string body)
    (Httpaf.Body.Writer.write_bigstring body)
    (Httpaf.Body.Writer.flush body)
    (fun _code -> Httpaf.Body.Writer.close body)

let forward_body_h2
    (response : Message.response)
    (body : [ `write ] H2.Body.t) =

  forward_body_general
    response
    (H2.Body.write_string body)
    (H2.Body.write_bigstring body)
    (H2.Body.flush body)
    (fun _code -> H2.Body.close_writer body)
