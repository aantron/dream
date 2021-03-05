module Dream =
struct
  include Dream_pure.Inmost
  module Log = Log
end



type route = Dream.method_ * string * Dream.handler

let get pattern handler =
  `GET, pattern, handler

let post pattern handler =
  `POST, pattern, handler



(* TODO Test with query strings; it should fail. *)
let matches request route =
  let (method_, pattern, handler) = route in

  if method_ <> Dream.method_ request then
    None
  else
    match Re.Pcre.extract ~rex:pattern (Dream.target request) with
    | exception Not_found ->
      None
    | groups ->
      Some (groups, handler)



let name =
  "dream.router"

let log =
  Dream.Log.source name

(* TODO LATER Pretty-print for the debugger. *)
let path_parameters =
  Dream.new_local ()

let path_parameter index request =
  try (Dream.local path_parameters request).(index)
  with _ ->
    let message = Printf.sprintf "Invalid path parameter index %i" index in
    log.error (fun log -> log "%s" message);
    failwith message

(* TODO LATER Switch from PCRE to some kind of trie; also index parameters by
   names rather than numbers. *)
let router ?on_match routes =

  (* If there is on-match middleware, immediately wrap all the handlers in
     it. *)
  let routes =
    match on_match with
    | None -> routes
    | Some middleware ->
      routes |> List.map (fun (method_, pattern, handler) ->
        (method_, pattern, middleware handler))
  in

  (* Convert each route into a pre-compiled PCRE. *)
  let routes =
    routes |> List.map (fun (method_, pattern, handler) ->
      (method_, Re.Pcre.regexp ("^" ^ pattern ^ "$"), handler))
  in

  (* The middleware proper. Find the first matching route, and set the matching
     groups in a request-local variable. *)
  fun next_handler request ->
    let rec try_routes = function
      | [] -> next_handler request
      | route::routes ->
        match matches request route with
        | None -> try_routes routes
        | Some (groups, handler) ->
          handler (Dream.with_local path_parameters groups request)
    in
    try_routes routes
