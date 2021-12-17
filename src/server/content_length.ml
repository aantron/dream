(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost



(* TODO Also mind Connection: close. *)
(* TODO Test in integration with HTTP/2. *)
(* TODO This could be renamed transfer_encoding at this point. *)
(* Add a Content-Length header to HTTP 1.x responses that have a fixed body but
   don't yet have the header. *)
let content_length next_handler request =
  if fst (Dream.version request) <> 1 then
    next_handler request
  else
    let%lwt (response : Dream.response) = next_handler request in
    if not (Dream.has_header response "Transfer-Encoding") then
      Dream.add_header response "Transfer-Encoding" "chunked";
    Lwt.return response
