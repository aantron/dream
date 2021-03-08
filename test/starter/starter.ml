let () =
  Dream.Log.initialize ~level:`Debug ()

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.catch ~debug:true
  @@ Dream.sessions
  @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "xyz");
    Dream.get "/def" (fun _ -> Dream.respond "uvw");
    Dream.get "/echo/:s" (fun request -> Dream.respond (Dream.crumb "s" request));
  ]
  @@ Dream.form
  @@ Dream.csrf
  @@ fun request ->
    let body =
      match Dream.cookie_option "id" request with
      | None -> "no cookie"
      | Some value -> value
    in

    let body =
      Dream.form_get request
      |> List.map (fun (name, value) -> Printf.sprintf "%s: %s" name value)
      |> String.concat "\n"
      |> (^) body
    in

    Dream.response body
    |> Dream.add_set_cookie "id" "1234"
    |> Lwt.return
    (* Dream.respond ~status:`Not_found "Good morning, world!" *)

(* TODO LATER Max-length middleware. *)
(* TODO LATER Predefine responses for common content-types. *)
(*
```ocaml
let () =
  Dream.run (fun _request ->
    Dream.respond "Good morning, world!")
``` *)

(* TODO Retire this file in favor of examples. *)

(* TODO LATER Alias Lwt.return, >|=, and >>=. *)
(* TODO LATER Version the router. *)

(* TODO LATER All the ways to compose middlewares: above handlers, at each
   handler, under routers, using some pre-composition (e.g. some kind of apply
   to list of handlers function). *)
