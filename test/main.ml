let () =
  Dream.run
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.catch ~debug:true
  @@ Dream.content_length
  @@ Dream.synchronous

  @@ fun _request ->
    ignore (assert false);
    Dream.response ~status:`Forbidden ()
    (* |> Dream.with_body "Good morning, world!" *)

(* TODO LATER Max-length middleware. *)
(* TODO LATER Predefine responses for common content-types. *)
(* TODO Add Dream.respond. *)
