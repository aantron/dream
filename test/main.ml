let () =
  Dream.run
  @@ Dream.request_id
  @@ Dream.logger
  @@ Dream.catch ~debug:true
  @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "xyz");
    Dream.get "/def" (fun _ -> Dream.respond "uvw");
    Dream.get "/echo/([^/?]+)" (fun request -> Dream.respond (Dream.path_parameter 1 request));
  ]
  @@ fun _request ->
    Dream.respond ~status:`Not_found "Good morning, world!"

(* TODO LATER Max-length middleware. *)
(* TODO LATER Predefine responses for common content-types. *)
(*
```ocaml
let () =
  Dream.run (fun _request ->
    Dream.respond "Good morning, world!")
``` *)

(* TODO LATER Alias Lwt.return, >|=, and >>=. *)
(* TODO LATER Version the router. *)

(* TODO LATER All the ways to compose middlewares: above handlers, at each
   handler, under routers, using some pre-composition (e.g. some kind of apply
   to list of handlers function). *)
