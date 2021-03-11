(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost



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
  | (Variable "")::_ -> false
  | [_] -> true
  | (Literal "")::_ -> false
  | _::more -> validate more

(* TODO Permit lack of leading /. *)
(* TODO Permit double /. *)
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
      failwith "Expected '/'" (* TODO Location. *)

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
    failwith "Invalid route" (* TODO Better description. *)
  else
    tokens

let rec strip_empty_trailing_token = function
  | [] -> []
  | [Literal ""] -> []
  | token::tokens -> token::(strip_empty_trailing_token tokens)



type node =
  | Leaf of Dream.method_ * Dream.handler
  | Subsite of route

and route = (token list * node) list

let get pattern handler =
  [parse pattern, Leaf (`GET, handler)]

let post pattern handler =
  [parse pattern, Leaf (`POST, handler)]

let rec apply middlewares routes =
  let rec compose handler = function
    | [] -> handler
    | middleware::more -> middleware @@ compose handler more
  in
  routes
  |> List.flatten
  |> List.map (fun (pattern, node) ->
    let node =
      match node with
      | Leaf (method_, handler) -> Leaf (method_, compose handler middlewares)
      | Subsite route -> Subsite (apply middlewares [route])
    in
    pattern, node)

let under prefix routes =
  [strip_empty_trailing_token (parse prefix), Subsite (List.flatten routes)]

let scope prefix middlewares routes =
  under prefix [apply middlewares routes]



(* TODO LATER Pretty-print for the debugger. *)
let crumbs : (string * string) list Dream.local =
  Dream.new_local ()

let crumb index request =
  try List.assoc index (Dream.local crumbs request)
  with _ -> Printf.ksprintf failwith "Invalid path parameter '%s'" index
  (* TODO Should this be logged? *)

let router routes =
  let routes = List.flatten routes in

  fun next_handler request ->

    let rec find_route bindings prefix path = function
      | [] -> None
      | (pattern, node)::routes ->
        let rec match_pattern bindings prefix pattern path =
          match pattern, path with
          | [], _ -> Some (bindings, List.rev prefix, path)
          | _, [] -> None
          | (Literal s)::pattern, s'::path ->
            if s = s' then
              match_pattern bindings (s::prefix) pattern path
            else
              None
          | (Variable s)::pattern, s'::path ->
            if s' = "" then
              None
            else
              match_pattern ((s, s')::bindings) (s'::prefix) pattern path
        in
        match match_pattern bindings prefix pattern path with
        | None ->
          find_route bindings prefix path routes
        | Some (new_bindings, new_prefix, new_path) ->
          match node with
          | Leaf (method_, handler) ->
            if method_ = Dream.method_ request && new_path = [] then
              let request =
                request
                |> Dream.with_local crumbs new_bindings
                |> Dream.with_prefix prefix
                |> Dream.with_path path
              in
              Some (handler, Dream.with_local crumbs new_bindings request)
            else
              find_route bindings prefix path routes
          | Subsite new_routes ->
            match find_route new_bindings (prefix @ new_prefix) new_path new_routes with
            | Some _ as result -> result
            | None -> find_route bindings prefix path routes
    in

    (* TODO The initial bindings and prefix should be taken from the request
       context. *)
    match find_route [] (Dream.internal_prefix request) (Dream.internal_path request) routes with
    | None -> next_handler request
    | Some (handler, request) -> handler request
