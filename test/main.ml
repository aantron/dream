let () =
  Dream.run
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.content_length
  @@ Dream.synchronous

  @@ fun _request ->
    Dream.response ()
    |> Dream.set_body "VERY KEWL"

(* TODO Max-length middleware. *)
(* TODO Predefine responses for common content-types. *)
