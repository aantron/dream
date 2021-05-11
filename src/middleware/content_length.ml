(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* TODO This belongs in the core module. *)
(* let add_header response buffered_body =
  let length =
    match buffered_body with
    | `Empty -> 0
    | `String body -> String.length body
  in
  Lwt.return
    (Dream.add_header "Content-Length" (string_of_int length) response) *)

(* TODO Also mind Connection: close. *)
(* TODO Test in integration with HTTP/2. *)
(* Add a Content-Length header to HTTP 1.x responses that have a fixed body but
   don't yet have the header. *)
let content_length next_handler request =

  if fst (Dream.version request) <> 1 then
    next_handler request

  else
    let%lwt (response : Dream.response) = next_handler request in

    let body_length =
      match !(response.body) with
      | `Empty -> Some 0
      | `String string -> Some (String.length string)
      | `Stream _ | `Exn _ -> None
    in

    match body_length with
    | Some length ->
      if Dream.has_header "Content-Length" response then
        Lwt.return response
      else
        response
        |> Dream.add_header "Content-Length" (string_of_int length)
        |> Lwt.return
    | None ->
      if Dream.has_header "Transfer-Encoding" response then
        Lwt.return response
      else
        response
        |> Dream.add_header "Transfer-Encoding" "chunked"
        |> Lwt.return
