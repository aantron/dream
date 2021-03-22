(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Method
include Status

type bigstring = Body.bigstring



module Scope_variable_metadata =
struct
  type 'a t = ('a -> string * string) option
end
module Scope = Hmap.Make (Scope_variable_metadata)

type app = {
  globals : Scope.t ref;
  mutable debug : bool;
  mutable secret : string;
}

let debug app =
  app.debug

let set_debug value app =
  app.debug <- value

let secret app =
  app.secret

let set_secret secret app =
  app.secret <- secret

let new_app () = {
  globals = ref Scope.empty;
  debug = false;
  secret = "";
}
(* TODO The empty string secret will never be used the way the code is currently
   set up. However, that it needs to be used temporarily suggests that the code
   is ill-factored. *)

type 'a message = {
  specific : 'a;
  headers : (string * string) list;
  body : Body.body_cell;
  locals : Scope.t;
  first : 'a message;
  last : 'a message ref;
}

type incoming = {
  app : app;
  client : string;
  method_ : method_;
  target : string;
  prefix : string list;
  path : string list;
  query : (string * string) list;
  request_version : int * int;
}
(* Prefix is stored backwards. *)

type websocket = {
  send : [ `Text | `Binary ] -> string -> unit Lwt.t;
  receive : unit -> string option Lwt.t;
  close : unit -> unit Lwt.t;
}

type outgoing = {
  status : status;
  websocket : (websocket -> unit Lwt.t) option;
}

type request = incoming message
type response = outgoing message

type 'a promise = 'a Lwt.t

type handler = request -> response Lwt.t
type middleware = handler -> handler

let first message =
  message.first

let last message =
  !(message.last)

let update message =
  message.last := message;
  message

let client request =
  request.specific.client

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let internal_prefix request =
  request.specific.prefix

let internal_path request =
  request.specific.path

let prefix request =
  Formats.make_path (List.rev request.specific.prefix)

let path request =
  Formats.make_path request.specific.path

let version request =
  request.specific.request_version

let with_client client request =
  update {request with specific = {request.specific with client}}

let with_method_ method_ request =
  update {request with specific = {request.specific with method_}}

let with_prefix prefix request =
  update {request with specific = {request.specific with prefix}}

let with_path path request =
  update {request with specific = {request.specific with path}}

let with_version version request =
  update {request with
    specific = {request.specific with request_version = version}}

let status response =
  response.specific.status

let all_queries request =
  request.specific.query

let query name request =
  List.assoc_opt name request.specific.query

let queries name request =
  request.specific.query
  |> List.fold_left (fun accumulator (name', value) ->
    if name' = name then
      value::accumulator
    else
      accumulator)
    []
  |> List.rev

let all_headers message =
  message.headers

let headers name message =
  let name = String.lowercase_ascii name in

  message.headers
  |> List.fold_left (fun matched (name', value) ->
    if String.lowercase_ascii name' = name then
      value::matched
    else
      matched)
    []
  |> List.rev

let header_basic name message =
  let name = String.lowercase_ascii name in
  message.headers
  |> List.find (fun (name', _) -> String.lowercase_ascii name' = name)
  |> snd

let header name message =
  try Some (header_basic name message)
  with Not_found -> None

let has_header name message =
  try ignore (header_basic name message); true
  with Not_found -> false

let add_header name value message =
  update {message with headers = message.headers @ [(name, value)]}

(* TODO Can optimize this if the header is not found? *)
let drop_header name message =
  let name = String.lowercase_ascii name in
  update {message with headers =
    message.headers
    |> List.filter (fun (name', _) -> String.lowercase_ascii name' <> name)}

let with_header name value message =
  message
  |> drop_header name
  |> add_header name value

(* TODO LATER Optimize by caching the parsed cookies in a local key. *)
(* TODO LATER: API: Dream.cookie : string -> request -> string, cookie-option...
   the thing with cookies is that they have a high likelihood of being absent. *)
(* TODO LATER Can decide whether to accept multiple Cookie: headers based on
   request version. But that would entail an actual middleware - is that worth
   it? *)
(* TODO LATER Also not efficient, at all. Need faster parser + the cache. *)
(* TODO DOC Using only raw cookies. *)
(* TODO However, is it best to URL-encode cookies by default, and provide a
   variable for opting out? *)
(* TODO DOC We allow multiple headers sent by the client, to support HTTP/2.
   What is this about? *)
let all_cookies request =
  request
  |> headers "Cookie"
  |> List.map Formats.from_cookie
  |> List.flatten

(* TODO Don't use this exception-raising function, to avoid clobbering user
   backtraces more. *)
let cookie_exn name request =
  snd (all_cookies request |> List.find (fun (name', _) -> name' = name))

let cookie name request =
  try Some (cookie_exn name request)
  with Not_found -> None

(* TODO LATER Default encoding. *)
let add_set_cookie name value response =
  add_header "Set-Cookie" (Printf.sprintf "%s=%s" name value) response

let body message =
  Body.body message.body

let body_stream message =
  Body.body_stream message.body

let body_stream_bigstring data eof message =
  Body.body_stream_bigstring data eof message.body

(* Create a fresh ref. The reason this field has a ref is because it might get
   replaced when a body is forced read. That's not what's happening here - we
   are setting a new body. Indeed, there might be a concurrent read going on.
   That read should not override the new body. So let it mutate the old
   request's ref; we generate a new request with a new body ref. *)
let with_body body message =
  update {message with body = ref (`String body)}

let with_body_stream stream message =
  update {message with body = ref (`String_stream stream)}

let has_body message =
  Body.has_body message.body

(* TODO Rename. *)
let is_websocket response =
  response.specific.websocket

let fold_scope f initial scope =
  Scope.fold (fun (B (key, value)) accumulator ->
    match Scope.Key.info key with
    | None -> accumulator
    | Some converter ->
      let key_name, value_string = converter value in
      f key_name value_string accumulator)
    scope
    initial

type 'a local = 'a Scope.key

let new_local ?debug () =
  Scope.Key.create debug

let local key message =
  Scope.find key message.locals

let with_local key value message =
  update {message with locals = Scope.add key value message.locals}

let fold_locals f initial message =
  fold_scope f initial message.locals

type 'a global = {
  key : 'a Scope.key;
  initializer_ : unit -> 'a;
}

let new_global ?debug initializer_ = {
  key = Scope.Key.create debug;
  initializer_;
}

let global {key; initializer_} request =
  match Scope.find key !(request.specific.app.globals) with
  | Some value -> value
  | None ->
    let value = initializer_ () in
    request.specific.app.globals :=
      Scope.add key value !(request.specific.app.globals);
    value

let fold_globals f initial request =
  fold_scope f initial !(request.specific.app.globals)

let app request =
  request.specific.app

let request_from_http
    ~app
    ~client
    ~method_
    ~target
    ~version
    ~headers
    ~body =

  let path, query = Formats.from_target target in

  let rec request = {
    specific = {
      app;
      client;
      method_;
      target;
      prefix = [];
      path = Formats.from_target_path path;
      query = Formats.from_form_urlencoded query;
      request_version = version;
    };
    headers;
    body = ref (`Stream body);
    locals = Scope.empty;
    first = request; (* TODO LATER What OCaml version is required for this? *)
    last = ref request;
  } in

  request

(* TODO Unify these string-to-stream functions. *)
let string_to_stream string =
  let buffer = Lwt_bytes.of_string string in
  let sent = ref false in

  fun data eof ->
    if !sent then
      eof ()
    else begin
      sent := true;
      data buffer 0 (Lwt_bytes.length buffer)
    end

let request
    ?(client = "127.0.0.1:12345")
    ?(method_ = `GET)
    ?(target = "/")
    ?(version = 1, 1)
    ?(headers = [])
    body =

  request_from_http
    ~app:(new_app ())
    ~client
    ~method_
    ~target
    ~version
    ~headers
    ~body:(string_to_stream body)



let response
    ?status
    ?code
    ?(headers = [])
    body =

  let status =
    match status, code with
    | None, None -> `OK
    | Some status, _ -> status
    | None, Some code -> int_to_status code
  in

  let rec response = {
    specific = {
      status;
      websocket = None;
    };
    headers;
    body = ref `Empty;
    locals = Scope.empty;
    first = response;
    last = ref response;
  } in

  with_body body response

let respond
    ?status
    ?code
    ?headers
    body =

  response ?status ?code ?headers body
  |> Lwt.return

let websocket handler =
  let response = response ~status:`Switching_Protocols "" in
  let response =
    {response with specific =
      {response.specific with websocket = Some handler}}
  in
  Lwt.return response

let send ?(kind = `Text) message websocket =
  websocket.send kind message

let receive websocket =
  websocket.receive ()

let close websocket =
  websocket.close ()

let identity handler request =
  handler request

let rec pipeline middlewares handler =
  match middlewares with
  | [] -> handler
  | middleware::more -> middleware (pipeline more handler)
(* TODO Test pipelien after the List.rev fiasco. *)

let sort_headers headers =
  List.stable_sort (fun (name, _) (name', _) -> compare name name') headers

(* TODO Factor out body code into module Body, maybe also Stream. *)
(* TODO Declare a stream type and replace all "k" by more or feed. *)
