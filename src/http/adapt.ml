(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let address_to_string : Unix.sockaddr -> string = function
  | ADDR_UNIX path -> path
  | ADDR_INET (address, port) ->
    Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port



(* TODO Write a test simulating client exit during SSE; this was killing the
   server at some point. *)
(* TODO LATER Will also need to monitor buffer accumulation and use flush. *)
(* TODO Rewrite using Dream.next. *)
let forward_body_general
    (response : Dream.response)
    (write_string : ?off:int -> ?len:int -> string -> unit)
    (write_buffer : ?off:int -> ?len:int -> Dream.buffer -> unit)
    http_flush
    close =

  let rec send () =
    response
    |> Dream.next
      ~buffer
      ~string
      ~flush
      ~close
      ~exn:ignore

  and buffer chunk off len =
    write_buffer ~off ~len chunk;
    send ()

  and string chunk off len =
    write_string ~off ~len chunk;
    send ()

  and flush () =
    http_flush send

  in

  send ()

let forward_body
    (response : Dream.response)
    (body : Httpaf.Body.Writer.t) =

  forward_body_general
    response
    (Httpaf.Body.Writer.write_string body)
    (Httpaf.Body.Writer.write_bigstring body)
    (Httpaf.Body.Writer.flush body)
    (fun () -> Httpaf.Body.Writer.close body)

let forward_body_h2
    (response : Dream.response)
    (body : [ `write ] H2.Body.t) =

  forward_body_general
    response
    (H2.Body.write_string body)
    (H2.Body.write_bigstring body)
    (H2.Body.flush body)
    (fun () -> H2.Body.close_writer body)
