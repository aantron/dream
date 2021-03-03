type request = Opium.Request.t
type response = Opium.Response.t

type handler = request -> response Lwt.t
type middleware = handler -> handler

type method_ = Opium.Method.t

(* TOOD Will need something more composable. *)
let key = Opium.Context.Key.create ("fw.router", fun _ -> assert false)

open Opium.Request

(* TODO Can't leverage opium's router, because it requires opium metadata. *)
(* TODO So... can temporarily use PCRE syntax and sequential matching, just to
   get started? *)
let route ?(middleware = fun x -> x) routes default_handler =
  (* let map_handlers f (method_, path, handler) = (method_, path, f handler) in *)
  (* let transformed_routes = map_3 scoped_middleware routes in *)

  let routes =
    routes |> List.map begin fun (method_, pattern, handler) ->
      let path = Re.Pcre.regexp ("^" ^ pattern ^ "$")
      and handler = middleware handler
      in

      (method_, path, handler)
    end
  in

  (* method_ and target come from the request. The route is stored in the
     router. *)
  let route_matches req route =
    let (meth, pattern, handler) = route in

    if meth <> req.meth then
      None
    else
      match Re.Pcre.extract ~rex:pattern req.target with
      | exception Not_found ->
        None
      | groups ->
        Some (handler, groups)
  in

  fun req ->
    match List.find_map (route_matches req) routes with
    | Some (handler, groups) ->
      let req = {req with env = Opium.Context.add key groups req.env} in
      handler req
    | None ->
      default_handler req

let param req index =
  (Opium.Context.find_exn key req.env).(index)

let route_ method_ pattern handler = method_, pattern, handler

module Logger = Logger
module Utf8 = Utf8
