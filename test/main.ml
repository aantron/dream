let () =
  Dream.run
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.catch ~debug:true

  @@ fun _request ->
    Dream.respond "Good morning, world!"

(* TODO LATER Max-length middleware. *)
(* TODO LATER Predefine responses for common content-types. *)
(*
```ocaml
let () =
  Dream.run (fun _request ->
    Dream.respond "Good morning, world!")
``` *)
