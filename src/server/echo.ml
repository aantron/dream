(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Message = Dream_pure.Message
module Stream = Dream_pure.Stream



(* TODO Convert to streaming later. *)
let echo request =
  (* TODO Simplfy this code. Can in fact just pass the request's server stream
     as the response's client stream. *)
  let client_stream = Message.server_stream request in
  let server_stream = Stream.(stream no_reader no_writer) in
  Message.response client_stream server_stream
  |> Lwt.return
