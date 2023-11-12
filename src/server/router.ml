(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Formats = Dream_pure.Formats
module Message = Dream_pure.Message
module Method = Dream_pure.Method



(* TODO Limit character set to permit future extensions. *)
(* TODO Document *. *)
(* TODO Forbid wildcard scopes. *)
(* TODO Will need to restore staged prefixes once there is prefix-querying,
   middleware because it will need to know the prefix of the nearest router. *)
(* TODO For full site composition, any_method is needed to forward everything to
   a subsite handler. *)
(* TODO Restore the site prefix as a "built-in" middleware. This makes much more
   sense now that there is a unified error handler beneath it. *)

type token =
  | Literal of string
  | Param of string
  | Wildcard of string

let rec validate route = function
  | (Param "")::_ ->
    Printf.ksprintf failwith "Empty path parameter name in '%s'" route
  | [Wildcard "*"] ->
    ()
  | (Wildcard "*")::_ ->
    failwith "Path wildcard must be last"
  | (Wildcard _)::_ ->
    failwith "Path wildcard must be just '**'"
  | _::tokens ->
    validate route tokens
  | [] ->
    ()

let make_star_or_wildcard = function
  | "" -> Literal "*"
  | s -> Wildcard s

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
      parse_component tokens (fun s -> Param s) (index + 1) (index + 1)
    | '*' ->
      parse_component tokens make_star_or_wildcard (index + 1) (index + 1)
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



type method_set = [
  | Method.method_
  | `Any
]

let method_matches method_set method_ =
  match method_set with
  | #Method.method_ as method' -> Method.methods_equal method' method_
  | `Any -> true

type node =
  | Handler of method_set * Message.handler
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

let any pattern handler =
  [parse pattern, Handler (`Any, handler)]

let no_route =
  []

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



let path_field : string list Message.field =
  Message.new_field
    ~name:"dream.path"
    ~show_value:(fun path -> String.concat "/" path)
    ()

(* TODO It would be nice not to repeat the work of splitting the path and query
   string. *)
(* TODO Remove this from the API. *)
let path the_request =
  match Message.field the_request path_field with
  | Some path -> path
  | None ->
    Message.(Formats.(
      the_request |> target |> split_target |> fst |> from_path))

(* TODO Move site_prefix into this file and remove with_path from the API. *)
let set_path request path =
  Message.set_field request path_field path

(* Prefix is stored backwards. *)
let prefix_field : string list Message.field =
  Message.new_field
    ~name:"dream.prefix"
    ~show_value:(fun prefix -> String.concat "/" (List.rev prefix))
    ()

let internal_prefix request =
  match Message.field request prefix_field with
  | Some prefix -> prefix
  | None -> []

let prefix request =
  Formats.to_path (List.rev (internal_prefix request))

let set_prefix request prefix =
  Message.set_field request prefix_field prefix

let params_field : (string * string) list Message.field =
  Message.new_field
    ~name:"dream.params"
    ~show_value:(fun params ->
      params
      |> List.map (fun (param, value) -> Printf.sprintf "%s=%s" param value)
      |> String.concat ", ")
    ()



let log =
  Log.sub_log "dream.router"

let missing_param request name =
  let message = Printf.sprintf "Dream.param: missing path parameter %S" name in
  log.error (fun log -> log ~request "%s" message);
  failwith message

let param request name =
  match Message.field request params_field with
  | None -> missing_param request name
  | Some params ->
    try List.assoc name params
    with _ -> missing_param request name

let router routes =
  let routes = List.flatten routes in

  fun request ->

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
      | Param    _ :: _,       s' :: _ when s' = ""   -> fail ()
      | Param    s :: pattern, s' :: path ->
        try_route ((s, s')::bindings) (s'::prefix) path pattern node ok fail
      | Wildcard _ :: _,       _ ->
        try_node bindings prefix path node true ok fail

    and try_node bindings prefix path node is_wildcard ok fail =
      match node with
      | Handler (method_, handler)
          when method_matches method_ (Message.method_ request) ->
        Message.set_field request params_field bindings;
        if is_wildcard then begin
          set_prefix request prefix;
          set_path request path;
          ok handler request
        end
        else
          if path = [] then
            ok handler request
          else
            fail ()

      | Handler _ -> fail ()
      | Scope routes -> try_routes bindings prefix path routes ok fail

    in

    let params =
      match Message.field request params_field with
      | Some params -> params
      | None -> []
    in

    (* let next_prefix = Dream.next_prefix request *)
    let prefix = internal_prefix request in
    let path = path request in

    (* match match_site_prefix next_prefix path with
    | None -> next_handler request
    | Some path -> *)
      (* TODO The initial bindings and prefix should be taken from the request
         context when there is indirect nested router support. *)
    try_routes
      params prefix path routes
      (fun handler request -> handler request)
      (fun () -> Helpers.not_found request)
