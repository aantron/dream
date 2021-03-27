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

  (* TODO Use the most appropriate reader. *)
  (* TODO LATER Will also need to monitor buffer accumulation and use flush. *)
  let rec send_body () =
    match%lwt Dream.body_stream response with
    | None ->
      Httpaf.Body.close_writer body;
      Lwt.return_unit
    | Some data ->
      Httpaf.Body.write_string body data;
      send_body ()
  in

  (* TODO Proper handling of the promise. *)
  ignore (send_body ())

let forward_body_h2
    (response : Dream.response)
    (body : [ `write ] H2.Body.t) =

  (* TODO LATER Will also need to monitor buffer accumulation and use flush. *)
  let rec send_body () =
    match%lwt Dream.body_stream response with
    | None ->
      H2.Body.close_writer body;
      Lwt.return_unit
    | Some data ->
      H2.Body.write_string body data;
      send_body ()
  in

  ignore (send_body ())
