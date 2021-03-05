let () =
  Dream.run
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.content_length
  @@ Dream.synchronous

  @@ fun _request ->
    Lwt.async (fun () -> assert false);
    Dream.response ()
    |> Dream.set_body "VERY KEWL"

(* TODO LATER Max-length middleware. *)
(* TODO LATER Predefine responses for common content-types. *)
