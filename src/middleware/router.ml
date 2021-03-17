(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* TODO Compare HTTP methods at string. *)

type token =
  | Literal of string
  | Variable of string

let rec validate route = function
  | (Variable "")::_ ->
    Printf.ksprintf failwith "Empty path parameter name in '%s'" route

  | _::tokens -> validate route tokens
  | [] -> ()

let parse string =

  let rec parse_separator tokens index =
    match string.[index] with
    | '/' ->
      parse_component_start tokens (index + 1)
    | _ ->
      parse_component_start tokens index
    | exception Invalid_argument _ ->
      List.rev tokens

  and parse_component_start tokens index =
    match string.[index] with
    | '/' ->
      parse_component_start tokens (index + 1)
    | ':' ->
      parse_component tokens (fun s -> Variable s) (index + 1) (index + 1)
    | _ | exception Invalid_argument _ ->
      parse_component tokens (fun s -> Literal s) index index

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
  validate string tokens;
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

let put pattern handler =
  [parse pattern, Leaf (`PUT, handler)]

let delete pattern handler =
  [parse pattern, Leaf (`DELETE, handler)]

let head pattern handler =
  [parse pattern, Leaf (`HEAD, handler)]

let connect pattern handler =
  [parse pattern, Leaf (`CONNECT, handler)]

let options pattern handler =
  [parse pattern, Leaf (`OPTIONS, handler)]

let trace pattern handler =
  [parse pattern, Leaf (`TRACE, handler)]

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

let log =
  Log.sub_log "dream.router"

let missing_crumb name request =
  let message = Printf.sprintf "Dream.crumb: missing path parameter %S" name in
  log.error (fun log -> log ~request "%s" message);
  failwith message

let crumb name request =
  match Dream.local crumbs request with
  | None -> missing_crumb name request
  | Some crumbs ->
    try List.assoc name crumbs
    with _ -> missing_crumb name request

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
            let subroute =
              find_route new_bindings (prefix @ new_prefix) new_path new_routes
            in
            match subroute with
            | Some _ as result -> result
            | None -> find_route bindings prefix path routes
    in

    (* The next_prefix mechanism is intended for composable indirect routing in
       the future (i.e. another router hidden in a handler, rather than more
       routes included with Dream.scope). It is currently only used to pass the
       site prefix down to the one and only supported top-level router, in order
       to avoid having to make a decision about how to fail (502?) above the
       application code if the target does not match the site prefix.

       This code will need to be rearranged somewhat to adapt it for indierct
       composable routers, mainly to build the prefixes incrementally off each
       other. *)
    let rec match_site_prefix prefix path =

      match prefix, path with
      | prefix_crumb::prefix, path_crumb::path ->
        if path_crumb = prefix_crumb then
          match_site_prefix prefix path
        else
          None

      | [], path ->
        Some path
      | _ ->
        None
    in

    let next_prefix = Dream.next_prefix request
    and path = Dream.internal_path request
    in

    match match_site_prefix next_prefix path with
    | None -> next_handler request
    | Some path ->
      (* The initial bindings and prefix should be taken from the request
         context when there is indirect nested router support. *)
      let route = find_route [] next_prefix path routes in
      match route with
      | None -> next_handler request
      | Some (handler, request) -> handler request
