(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost



(* TODO In order to switch to the nesting DSL-like API, the routes have to
   become fat: something like lists of method, string, handler. *)
type one_route = Dream.method_ * string * Dream.handler
type route = one_route list

let get pattern handler =
  [`GET, pattern, handler]

let post pattern handler =
  [`POST, pattern, handler]

let apply middlewares routes =
  let rec compose handler = function
    | [] -> handler
    | middleware::more -> middleware @@ compose handler more
  in
  routes
  |> List.flatten
  |> List.map (fun (method_, pattern, handler) ->
    method_, pattern, compose handler middlewares)

(* TODO Need to handle the prefix extension and path chopping. *)
(* TODO Need to handle variables in the prefix. *)
let under prefix routes =
  routes
  |> List.flatten
  |> List.map (fun (method_, pattern, handler) ->
    method_, prefix ^ pattern, handler)



(* TODO Test with query strings; it should fail. *)
let matches request one_route =
  let (method_, pattern, names, handler) = one_route in

  if method_ <> Dream.method_ request then
    None
  else
    match Re.Pcre.extract ~rex:pattern (Dream.target request) with
    | exception Not_found ->
      None
    | groups ->
      let groups = List.tl @@ Array.to_list groups in
      let groups = List.combine names groups in
      Some (groups, handler)



(* TODO Need a parser somewhere. Gramamr is like... Paths begin with... a
separator, either / or /:. if /, the next component is a literal. If /:, it is
a crumb. Components are not allowed to be empty, except the last component if it
is not a crumb. Crumbs can never be empty.
 *)
type token =
  | Literal of string
  | Variable of string

let rec validate = function
  | [] -> false
  | [Variable ""] -> false
  | [_] -> true
  | (Literal "")::_ -> false
  | (Variable "")::_ -> false
  | _::more -> validate more

let parse string =

  let rec parse_separator tokens index =
    match string.[index] with
    | '/' ->
      let constructor, index =
        match string.[index + 1] with
        | ':' ->
          (fun s -> Variable s), index + 2
        | _ | exception Invalid_argument _ ->
          (fun s -> Literal s), index + 1
      in
      parse_component tokens constructor index index
    | _ | exception Invalid_argument _ ->
      failwith "foo" (* TODO *)

  and parse_component tokens constructor start_index index =
    match string.[index] with
    | exception Invalid_argument _ ->
      let token =
        constructor (String.sub string start_index (index - start_index)) in
      List.rev (token::tokens)
    | '/' ->
      let token =
        constructor (String.sub string start_index (index - start_index)) in
      parse_separator (token::tokens) index
    | _ ->
      parse_component tokens constructor start_index (index + 1)

  in

  let tokens = parse_separator [] 0 in
  if not @@ validate tokens then
    failwith "bar" (* TODO *)
  else
    tokens
(* TODO Provide V1 router. *)



let name =
  "dream.router"

let log =
  Log.source name

(* TODO LATER Pretty-print for the debugger. *)
let crumbs : (string * string) list Dream.local =
  Dream.new_local ()

let crumb index request =
  try List.assoc index (Dream.local crumbs request)
  with _ ->
    let message = Printf.sprintf "Invalid path parameter index %s" index in
    log.error (fun log -> log "%s" message);
    failwith message

(* TODO LATER Switch from PCRE to some kind of trie; also index parameters by
   names rather than numbers. *)
let router routes =

  (* Convert each route into a pre-compiled PCRE. *)
  let routes =
    routes
    |> List.flatten
    |> List.map (fun (method_, pattern, handler) ->
      let tokens = parse pattern in

      (* TODO So ugly. *)
      let re =
        tokens
        |> List.map (function
          | Literal s -> Re.str ("/" ^ s)
          | Variable _ -> Re.(seq [char '/'; group (rep1 any)]))
        |> fun re -> Re.(seq (bos::re @ [eos]))
        |> Re.compile
      in

      let names =
        tokens
        |> List.fold_left (fun names -> function
          | Literal _ -> names
          | Variable s -> s::names) []
        |> List.rev
      in

      (method_, re, names, handler))
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
          handler (Dream.with_local crumbs groups request)
    in
    try_routes routes
