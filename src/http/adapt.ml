(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let address_to_string : Unix.sockaddr -> string = function
  | ADDR_UNIX path -> path
  | ADDR_INET (address, port) ->
    Printf.sprintf "%s:%i" (Unix.string_of_inet_addr address) port



(* TODO LATER Will also need to monitor buffer accumulation and use flush. *)
let forward_body_general
    (response : Dream.response)
    write_string
    (write_bigstring : ?off:int -> ?len:int -> Dream.bigstring -> unit)
    close =

  match !(response.body) with
  | `Empty ->
    close ()

  | `String string ->
    write_string string;
    close ();

  | `String_stream _ ->
    let rec send () =
      match%lwt Dream.body_stream response with
      | None ->
        close ();
        Lwt.return_unit
      | Some string ->
        write_string string;
        send ()
    in

    (* TODO Exception and rejection handling. Is it necessary? *)
    ignore (send ())

  (* TODO Is exception handling necessary here? Need integration testing. *)
  | `Bigstring_stream _ ->
    let rec send () =
      Dream.body_stream_bigstring
        (fun data offset length ->
          write_bigstring ~off:offset ~len:length data;
          send ())
        (fun () ->
          close ())
        response
    in
    send ()

let forward_body
    (response : Dream.response)
    (body : [ `write ] Httpaf.Body.t) =

  forward_body_general
    response
    (Httpaf.Body.write_string body)
    (Httpaf.Body.write_bigstring body)
    (fun () -> Httpaf.Body.close_writer body)

let forward_body_h2
    (response : Dream.response)
    (body : [ `write ] H2.Body.t) =

  forward_body_general
    response
    (H2.Body.write_string body)
    (H2.Body.write_bigstring body)
    (fun () -> H2.Body.close_writer body)
