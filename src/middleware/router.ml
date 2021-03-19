(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* TODO Compare HTTP methods at string. *)
(* TODO Test wildcards. *)
(* TODO Limit character set to permit future extensions. *)
(* TODO Document *. *)
(* TODO Forbid wildcard scopes. *)
(* TODO Will need to restore staged prefixes once there is prefix-querying,
   middleware because it will need to know the prefix of the nearest router. *)

type token =
  | Literal of string
  | Crumb of string
  | Wildcard of string

let rec validate route = function
  | (Crumb "")::_ ->
    Printf.ksprintf failwith "Empty path parameter name in '%s'" route
  | [Wildcard ""] ->
    ()
  | (Wildcard "")::_ ->
    failwith "Path wildcard must be last"
  | (Wildcard _)::_ ->
    failwith "Path wildcard must be just '*'"
  | _::tokens ->
    validate route tokens
  | [] ->
    ()

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
      parse_component tokens (fun s -> Crumb s) (index + 1) (index + 1)
    | '*' ->
      parse_component tokens (fun s -> Wildcard s) (index + 1) (index + 1)
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
  | Handler of Dream.method_ * Dream.handler
  | Scope of route

and route = (token list * node) list

let get pattern handler =
  [parse pattern, Handler (`GET, handler)]

let post pattern handler =
  [parse pattern, Handler (`POST, handler)]

let put pattern handler =
  [parse pattern, Handler (`PUT, handler)]

let delete pattern handler =
  [parse pattern, Handler (`DELETE, handler)]

let head pattern handler =
  [parse pattern, Handler (`HEAD, handler)]

let connect pattern handler =
  [parse pattern, Handler (`CONNECT, handler)]

let options pattern handler =
  [parse pattern, Handler (`OPTIONS, handler)]

let trace pattern handler =
  [parse pattern, Handler (`TRACE, handler)]

let patch pattern handler =
  [parse pattern, Handler (`PATCH, handler)]

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
      | Handler (method_, handler) ->
        Handler (method_, compose handler middlewares)
      | Scope route -> Scope (apply middlewares [route])
    in
    pattern, node)

let under prefix routes =
  [strip_empty_trailing_token (parse prefix), Scope (List.flatten routes)]

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

    (* TODO Probably unnecessary (because it's better to just convert this to a
       trie), but the method can be checked before descending down the route. *)

    let rec try_routes bindings prefix path routes ok fail =
      match routes with
      | [] -> fail ()
      | (pattern, node)::routes ->
        try_route bindings prefix path pattern node ok (fun () ->
          try_routes bindings prefix path routes ok fail)

    and try_route bindings prefix path pattern node ok fail =
      match pattern, path with
      | [], _ ->
        try_node bindings prefix path node false ok fail
      | _,  [] -> fail ()
      | Literal  s :: pattern, s' :: path when s = s' ->
        try_route bindings            (s'::prefix) path pattern node ok fail
      | Literal  _ :: _,       _                      -> fail ()
      | Crumb    _ :: _,       s' :: _ when s' = ""   -> fail ()
      | Crumb    s :: pattern, s' :: path ->
        try_route ((s, s')::bindings) (s'::prefix) path pattern node ok fail
      | Wildcard _ :: _,       _ ->
        try_node bindings prefix path node true ok fail

    and try_node bindings prefix path node is_wildcard ok fail =
      match node with
      | Handler (method_, handler)
          when method_ = Dream.method_ request &&
               (path = [] || is_wildcard) ->
        request
        |> Dream.with_local crumbs bindings
        |> Dream.with_prefix prefix
        |> Dream.with_path path
        |> ok handler
      | Handler _ -> fail ()
      | Scope routes -> try_routes bindings prefix path routes ok fail

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
      try_routes
        [] next_prefix path routes
        (fun handler request -> handler request)
        (fun () -> next_handler request)
