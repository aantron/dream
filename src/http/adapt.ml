(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let address_to_string : Unix.sockaddr -> string = function
  | ADDR_UNIX path -> path
  | ADDR_INET (address, port) ->
    Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port



let forward_body
    (response : Dream.response)
    (body : [ `write ] Httpaf.Body.t) =

  let body_stream =
    Dream.body_stream response in

  (* TODO LATER Will also need to monitor buffer accumulation and use flush. *)
  let rec send_body () =
    body_stream begin function
    | None -> Httpaf.Body.close_writer body
    | Some chunk ->
      Httpaf.Body.write_bigstring body chunk;
      send_body ()
    end
  in

  send_body ()

let forward_body_h2
    (response : Dream.response)
    (body : [ `write ] H2.Body.t) =

  let body_stream =
    Dream.body_stream response in

  (* TODO LATER Will also need to monitor buffer accumulation and use flush. *)
  let rec send_body () =
    body_stream begin function
    | None -> H2.Body.close_writer body
    | Some chunk ->
      H2.Body.write_bigstring body chunk;
      send_body ()
    end
  in

  send_body ()
