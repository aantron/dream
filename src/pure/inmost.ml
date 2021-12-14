(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Method
include Status



(* Used for converting the stream interface of [multipart_form] into the pull
   interface of Dream.

   [state] permits to dissociate the initial state made by
   [initial_multipart_state] and one which started to consume the body stream
   (see the call of [Upload.upload]). *)
type multipart_state = {
  mutable state_init : bool;
  mutable name : string option;
  mutable filename : string option;
  mutable stream : (< > * Multipart_form.Header.t * string Lwt_stream.t) Lwt_stream.t;
}

let initial_multipart_state () = {
  state_init = true;
  name = None;
  filename = None;
  stream = Lwt_stream.of_list [];
}

module Scope_variable_metadata =
struct
  type 'a t = string option * ('a -> string) option
end
module Scope = Hmap.Make (Scope_variable_metadata)

type websocket = Stream.stream

type request = client message
and response = server message

and 'a message = {
  specific : 'a;
  headers : (string * string) list;
  client_stream : Stream.stream;
  server_stream : Stream.stream;
  locals : Scope.t;
  first : 'a message;
  last : 'a message ref;
}

and client = {
  method_ : method_;
  target : string;
  request_version : int * int;
  upload : multipart_state;
}

and server = {
  status : status;
  websocket : (websocket -> unit Lwt.t) option;
}

and error_handler = error -> response option Lwt.t

and log_level = [
  | `Error
  | `Warning
  | `Info
  | `Debug
]

and error = {
  condition : [
    | `Response of response
    | `String of string
    | `Exn of exn
  ];
  layer : [
    | `TLS
    | `HTTP
    | `HTTP2
    | `WebSocket
    | `App
  ];
  (* TODO Any point in distinguishing HTTP and HTTP2 errors? *)
  caused_by : [
    | `Server
    | `Client
  ];
  request : request option;
  response : response option;
  client : string option;
  severity : [
    | `Error
    | `Warning
    | `Info
    | `Debug
  ];
  will_send_response : bool;
}

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

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let version request =
  request.specific.request_version

let with_method_ method_ request =
  update {request with
    specific = {request.specific with method_ = (method_ :> method_)}}

let with_version version request =
  update {request with
    specific = {request.specific with request_version = version}}

let status response =
  response.specific.status

let all_headers message =
  message.headers

let with_all_headers headers message =
  update {message with headers}

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
(* let cookie_exn name request =
  snd (all_cookies request |> List.find (fun (name', _) -> name' = name))

let cookie name request =
  try Some (cookie_exn name request)
  with Not_found -> None *)

(* TODO NOTE On the client, this will read the client stream until close. *)
let body message =
  Stream.read_until_close message.server_stream

let read message =
  Stream.read_convenience message.server_stream

let client_stream message =
  message.client_stream

let server_stream message =
  message.server_stream

let with_client_stream client_stream message =
  update {message with client_stream}

(* TODO Pending the dream.mli interface reorganization for the new stream
   API. *)
let next =
  Stream.read

(* Create a fresh ref. The reason this field has a ref is because it might get
   replaced when a body is forced read. That's not what's happening here - we
   are setting a new body. Indeed, there might be a concurrent read going on.
   That read should not override the new body. So let it mutate the old
   request's ref; we generate a new request with a new body ref. *)
(* TODO NOTE In Dream, this should operate on response server_streams. In Hyper,
   it should operate on request client_streams, although there is no very good
   reason why it can't operate on general messages, which might be useful in
   middlewares that preprocess requests on the server and postprocess responses
   on the client. Or.... shouldn't this affect the client stream on the server,
   replacing its read end? *)
let with_body body message =
  (* TODO This is partially redundant with a length check in Stream.string, but
     that check is no longer useful as it prevents allocation of only a reader,
     rather than a complete stream. *)
  let body =
    if String.length body = 0 then
      (* TODO Should probably preallocate this as a stream. *)
      Stream.(stream empty no_writer)
    else
      Stream.(stream (string body) no_writer)
  in
  update {message with server_stream = body}

(* TODO The critical piece: the pipe should be split between the client and
   server streams. adapt.ml should be reading from the client stream. *)
let with_stream message =
  let reader, writer = Stream.pipe () in
  let client_stream = Stream.stream reader Stream.no_writer in
  let server_stream = Stream.stream Stream.no_reader writer in
  update {message with client_stream; server_stream}

(* TODO Need to expose FIN. However, it can't have any effect even on
   WebSockets, because websocket/af does not offer the ability to pass FIN. It
   is hardcoded to true. *)
(* TODO Also expose binary/text. *)
let write message chunk =
  let promise, resolver = Lwt.wait () in
  let length = String.length chunk in
  let buffer = Bigstringaf.of_string ~off:0 ~len:length chunk in
  (* TODO Better handling of close? But it can't even occur with http/af. *)
  Stream.write
    message.server_stream
    buffer 0 length true false
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    (Lwt.wakeup_later resolver);
  promise

let write_buffer ?(offset = 0) ?length message chunk =
  let promise, resolver = Lwt.wait () in
  let length =
    match length with
    | Some length -> length
    | None -> Bigstringaf.length chunk - offset
  in
  (* TODO Proper handling of close. *)
  (* TODO As above, properly expose FIN. *)
  (* TODO Also expose binary/text. *)
  Stream.write
    message.server_stream
    chunk offset length true false
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    (Lwt.wakeup_later resolver);
  promise

(* TODO How are remote closes actually handled? There is no way for http/af to
   report them to the user application through the writer. *)
let flush message =
  let promise, resolver = Lwt.wait () in
  Stream.flush
    message.server_stream
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    (Lwt.wakeup_later resolver);
  promise

let close_stream message =
  Stream.close message.server_stream 1000;
  Lwt.return_unit

(* TODO Rename. *)
let is_websocket response =
  response.specific.websocket

let fold_scope f initial scope =
  Scope.fold (fun (B (key, value)) accumulator ->
    match Scope.Key.info key with
    | Some name, Some show_value -> f name (show_value value) accumulator
    | _ -> accumulator)
    scope
    initial

type 'a local = 'a Scope.key

let new_local ?name ?show_value () =
  Scope.Key.create (name, show_value)

let local key message =
  Scope.find key message.locals

let with_local key value message =
  update {message with locals = Scope.add key value message.locals}

let fold_locals f initial message =
  fold_scope f initial message.locals

let request_from_http
    ~method_
    ~target
    ~version
    ~headers
    body =

  let rec request = {
    specific = {
      method_;
      target;
      request_version = version;
      upload = initial_multipart_state ();
    };
    headers;
    client_stream = Stream.(stream no_reader no_writer);
    server_stream = body;
    locals = Scope.empty;
    first = request; (* TODO LATER What OCaml version is required for this? *)
    last = ref request;
  } in

  request

let request
    ?method_
    ?(target = "/")
    ?(version = 1, 1)
    ?(headers = [])
    client_stream
    server_stream =

  let method_ =
    match (method_ :> method_ option) with
    | None -> `GET
    | Some method_ -> method_
  in

  (* This function is used for debugging, so it's fine to allocate a fake body
     and then immediately replace it. *)

  let rec request = {
    specific = {
      (* TODO Is there a better fake error handler? Maybe this function should
         come after the response constructors? *)
      method_;
      target;
      request_version = version;
      upload = initial_multipart_state ();
    };
    headers;
    client_stream;
    server_stream;
    locals = Scope.empty;
    first = request;
    last = ref request;
  } in

  request

let response
    ?status ?code ?(headers = []) client_stream server_stream =

  let status =
    match status, code with
    | None, None -> `OK
    | Some status, _ -> (status :> status)
    | None, Some code -> int_to_status code
  in

  let rec response = {
    specific = {
      status;
      websocket = None;
    };
    headers;
    client_stream;
    server_stream;
    (* TODO This fully dead stream should be preallocated. *)
    locals = Scope.empty;
    first = response;
    last = ref response;
  } in

  response

let websocket ?headers handler =
  (* TODO Simplify stream creation. *)
  let client_stream = Stream.(stream empty no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  let response =
    response
      ?headers ~status:`Switching_Protocols client_stream server_stream in
  let response =
    {response with specific =
      {response.specific with websocket = Some handler}}
  in
  Lwt.return response

let send ?kind websocket message =
  let binary =
    match kind with
    | None | Some `Text -> false
    | Some `Binary -> true
  in
  let promise, resolver = Lwt.wait () in
  let length = String.length message in
  Stream.write
    websocket
    (Bigstringaf.of_string ~off:0 ~len:length message) 0 length
    binary true
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    (Lwt.wakeup_later resolver);
  (* TODO The API will likely have to change to report closing. *)
  promise

let receive websocket =
  Stream.read_convenience websocket

let close_websocket ?(code = 1000) websocket =
  Stream.close websocket code;
  Lwt.return_unit

let no_middleware handler request =
  handler request

let rec pipeline middlewares handler =
  match middlewares with
  | [] -> handler
  | middleware::more -> middleware (pipeline more handler)
(* TODO Test pipelien after the List.rev fiasco. *)

let sort_headers headers =
  List.stable_sort (fun (name, _) (name', _) -> compare name name') headers

(* TODO Remove to server-side code. *)
let multipart_state request =
  request.specific.upload
