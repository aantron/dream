(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Method
include Status

module Bigstring = Bigarray.Array1

(* TODO LATER It would be best if the web server would write straight into the
   framework's buffer, rather than first into its own, with copying to the
   framework following later. However, in the case of both http/af and h2, it
   appears that this will require at least a custom integration (at the same
   level as httpaf-lwt-unix), if it is currently possible at all. Fortunately,
   this will be an implementation detail of the framework, so we can profile and
   change it later, as an optimization. *)
type bigstring =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigstring.t

(* TODO LATER For now, Dream is following a simple model. The http server layer
   DOES NOT allocate a buffer, but stores a reading function in the request.
   When the body is actually needed by something in the web app, it is read to
   completion. *)
(* TODO LATER This exposes the framework to large request attacks. *)

(* Not every request will need body reading, so don't allocate a buffer for each
   requesst - only allocate it upon request. *)
type buffered_body = [
  | `Empty
  | `String of string
  | `Bigstring of bigstring
]

type body = [
  | buffered_body
  | `Bigstring_stream of (bigstring option -> unit) -> unit
  | `Reading of buffered_body Lwt.t
]

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
  body : body ref;
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
  next_prefix : string list;
  path : string list;
  request_version : int * int;
}

type outgoing = {
  (* response_version : (int * int) option; *)
  status : status;
  (* reason : string option; *)
  websocket : (string -> string Lwt.t) option;
}

type request = incoming message
type response = outgoing message

type 'a promise = 'a Lwt.t

type handler = request -> response Lwt.t
type middleware = handler -> handler

let new_bigstring length =
  Bigstring.create Bigarray.char Bigarray.c_layout length

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

let next_prefix request =
  request.specific.next_prefix

let internal_path request =
  request.specific.path

let prefix request =
  Formats.make_path request.specific.prefix

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

let with_next_prefix next_prefix request =
  update {request with specific = {request.specific with next_prefix}}

let with_path path request =
  update {request with specific = {request.specific with path}}

let with_version version request =
  update {request with
    specific = {request.specific with request_version = version}}

let status response =
  response.specific.status

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
let all_cookies request =
  request
  |> headers "Cookie"
  |> List.map Formats.from_cookie_encoded
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

(* TODO LATER Good defaults for path; taking the path from a request; middleware
   for site-wide cookies during prototyping. Needs prefix middleware in place
   first. *)

let has_body message =
  match !(message.body) with
  | `Empty -> false
  | `String "" -> false
  | `String _ -> true
  | `Bigstring body -> Bigstring.size_in_bytes body > 0
  | _ -> true

(* TODO LATER This is the preliminary reader implementation described in
   comments above. It should eventually be replaced by a 0-copy reader, but that
   will likely require a much more low-level web server integration. *)
let buffer_body message : buffered_body Lwt.t =
  match !(message.body) with
  | #buffered_body as body -> Lwt.return body
  | `Reading on_finished -> on_finished

  | `Bigstring_stream stream ->
    let on_finished, finished = Lwt.wait () in
    message.body := `Reading on_finished;

    let rec read body length =
      stream begin function
      | None ->
        let body =
          if Bigstring.size_in_bytes body = 0 then
            `Empty
          else
          `Bigstring (Bigstring.sub body 0 length)
        in
        message.body := body;
        Lwt.wakeup_later finished body

      | Some chunk ->
        let chunk_length = Bigstring.size_in_bytes chunk in
        let new_length = length + chunk_length in
        let body =
          if new_length <= Bigstring.size_in_bytes body then
            body
          else
            let new_body = new_bigstring (new_length * 2) in
            Bigstring.blit
              (Bigstring.sub body 0 length) (Bigstring.sub new_body 0 length);
            new_body
        in
        Bigstring.blit chunk (Bigstring.sub body length chunk_length);
        read body new_length
      end
    in

    read (new_bigstring 4096) 0;

    on_finished

let body request =
  buffer_body request
  |> Lwt.map begin function
    | `Empty -> ""
    | `String body -> body
    | `Bigstring body -> Lwt_bytes.to_string body
  end

(* TODO LATER There need to be buffering and unbuffering version of this. The
   HTTP server needs a version that does not buffer. The app, by default,
   should get buffering. *)
let buffered_body_stream body =
  let sent = ref false in

  fun k ->
    if !sent then
      k None
    else begin
      sent := true;
      match body with
      | `Empty -> k None
      | `String body -> k (Some (Lwt_bytes.of_string body))
      | `Bigstring body -> k (Some body)
    end

let body_stream request =
  match !(request.body) with
  | #buffered_body as body -> buffered_body_stream body
  | `Bigstring_stream stream -> stream
  | `Reading on_finished ->
    fun k ->
      Lwt.on_success on_finished (fun body -> buffered_body_stream body k)

(* Create a fresh ref. The reason this field has a ref is because it might get
   replaced when a body is forced read. That's not what's happening here - we
   are setting a new body. Indeed, there might be a concurrent read going on.
   That read should not override the new body. So let it mutate the old
   request's ref; we generate a new request with a new body ref. *)
let with_body ?(set_content_length = true) body response =
  let response = update {response with body = ref (`String body)} in
  if set_content_length then
    with_header "Content-Length" (string_of_int (String.length body)) response
  else
    response

(* let version_override response =
  response.specific.response_version

let reason_override response =
  response.specific.reason

let reason response =
  match reason_override response with
  | Some reason -> reason
  | None -> status_to_string response.specific.status *)

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

  let rec request = {
    specific = {
      app;
      client;
      method_;
      target;
      prefix = [];
      next_prefix = [];
      path = fst (Formats.parse_target target);
      request_version = version;
    };
    headers;
    body = ref (`Bigstring_stream body);
    locals = Scope.empty;
    first = request; (* TODO LATER What OCaml version is required for this? *)
    last = ref request;
  } in

  request

(* TODO Unify these string-to-stream functions. *)
let string_to_stream string =
  let sent = ref false in

  fun k ->
    if !sent then
      k None
    else begin
      sent := true;
      k (Some (Lwt_bytes.of_string string))
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
    (* ?version *)
    ?status
    ?code
    (* ?reason *)
    ?(headers = [])
    ?(set_content_length = true)
    body =

  let status =
    match status, code with
    | None, None -> `OK
    | Some status, _ -> status
    | None, Some code -> int_to_status code
  in

  let rec response = {
    specific = {
      (* response_version = version; *)
      status;
      (* reason; *)
      websocket = None;
    };
    headers;
    body = ref `Empty;
    locals = Scope.empty;
    first = response;
    last = ref response;
  } in

  with_body ~set_content_length body response

let respond
    (* ?version *)
    ?status
    ?code
    (* ?reason *)
    ?headers
    ?set_content_length
    body =

  response ?status ?code ?headers ?set_content_length body
  |> Lwt.return

let websocket handler =
  let response = response "" in
  let response =
    {response with specific = {response.specific with websocket = Some handler}}
  in
  Lwt.return response

let identity handler request =
  handler request

let rec pipeline middlewares =
  let middlewares = List.rev middlewares in
  fun handler ->
    match middlewares with
    | [] -> handler
    | middleware::more -> pipeline more (middleware handler)

let sort_headers headers =
  List.stable_sort (fun (name, _) (name', _) -> compare name name') headers

(* TODO Factor out body code into module Body, maybe also Stream. *)
(* TODO Declare a stream type and replace all "k" by more or feed. *)
