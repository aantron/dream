let () =
  Dream.run
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.content_length
  @@ Dream.synchronous

  @@ fun _request ->
    Dream.response ()
    |> Dream.with_body "VERY KEWL"

(* TODO LATER Max-length middleware. *)
(* TODO LATER Predefine responses for common content-types. *)
