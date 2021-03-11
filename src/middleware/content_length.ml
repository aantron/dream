(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let add_header response buffered_body =

  let length =
    match buffered_body with
    | `Empty -> 0
    | `String body -> String.length body
    | `Bigstring body -> Dream.Bigstring.size_in_bytes body
  in

  Lwt.return
    (Dream.add_header "Content-Length" (string_of_int length) response)



let assign ?(buffer_streams = false) next_handler request =
  let open Lwt.Infix in

  next_handler request
  >>= fun response ->

  if Dream.has_header "Content-Length" response then
    Lwt.return response

  else
    match !(response.body) with
    | #Dream.buffered_body as buffered_body ->
      add_header response buffered_body

    | _ ->
      if not buffer_streams then
        Lwt.return response
      else
        Dream.buffer_body response >>= add_header response
