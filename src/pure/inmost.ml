(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Method
include Status

type bigstring = Body.bigstring
(* type bigstring_stream = Body.bigstring_stream *)

type upload_event = [
  | `File of string * string
  | `Field of string * string
  | `Done
  | `Wrong_content_type
]

(* TODO multipart-form-data returns 4K-long chunks, so these should be
   represented as substreams. *)
(* type multipart_state = [
  | `Initial
  | `Awaiting of upload_event Lwt.u
  | `Uploading of string option Lwt.u * string * string
  | `First_chunk of string * string * unit Lwt.u
  | `Next_file of string * string * string * unit Lwt.u
  | `Files of string * string * unit Lwt.u
  | `Fields of (string * string) list
] *)

(* Used for converting the push interface of Multipart_form_data into the pull
   interface of Dream. *)
type multipart_state = {
  mutable initial : bool;
  mutable event_listener : upload_event Lwt.u option;
  mutable chunk_listener : string option Lwt.u option;
  mutable last_field_name : string option;
  mutable last_file_name : string option;
  mutable buffered_chunk : string option;
  mutable next_file : bool;
  mutable continue : unit Lwt.u;
  mutable fields : bool;
  mutable field : unit -> (string * string) option Lwt.t;
}

let initial_multipart_state () = {
  initial = true;
  event_listener = None;
  chunk_listener = None;
  last_field_name = None;
  last_file_name = None;
  buffered_chunk = None;
  next_file = false;
  continue = snd (Lwt.wait ());
  fields = false;
  field = fun () -> fst (Lwt.wait ());
}



(* TODO Temporary; Ciphers should depend on the core, not the other way. *)
module Cipher = Dream__cipher.Cipher

module Scope_variable_metadata =
struct
  type 'a t = string option * ('a -> string) option
end
module Scope = Hmap.Make (Scope_variable_metadata)

type app = {
  globals : Scope.t ref;
  mutable debug : bool;
  mutable https : bool;
  mutable secrets : string list;
}

let debug app =
  app.debug

let set_debug value app =
  app.debug <- value

(* TODO Delete; now using key. *)
let secret app =
  List.hd app.secrets

let set_secrets secrets app =
  app.secrets <- secrets

let new_app () = {
  globals = ref Scope.empty;
  debug = false;
  https = false;
  secrets = [];
}

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
  upload : multipart_state;
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

let https request =
  request.specific.app.https

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let internal_prefix request =
  request.specific.prefix

let prefix request =
  Formats.make_path (List.rev request.specific.prefix)

let path request =
  request.specific.path

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

(* TODO percent-decode name and value. *)
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

let body message =
  Body.body message.body

let read message =
  Body.read message.body

let next ~bigstring ?string ?flush ~close ~exn message =
  Body.next ~bigstring ?string ?flush ~close ~exn message.body

(* let body_stream_bigstring data eof message =
  Body.body_stream_bigstring data eof message.body *)

(* Create a fresh ref. The reason this field has a ref is because it might get
   replaced when a body is forced read. That's not what's happening here - we
   are setting a new body. Indeed, there might be a concurrent read going on.
   That read should not override the new body. So let it mutate the old
   request's ref; we generate a new request with a new body ref. *)
let with_body body message =
  let body =
    if String.length body = 0 then
      `Empty
    else
      `String body
  in
  update {message with body = ref body}

let with_stream message =
  update {message with body = ref (`Stream (ref `Idle))}

let write chunk message =
  Body.write chunk message.body

let write_bigstring chunk offset length message =
  Body.write_bigstring chunk offset length message.body

let flush message =
  Body.flush message.body

let close_stream message =
  Body.close_stream message.body

(* let with_body_stream_bigstring stream message =
  update {message with body = ref (`Bigstring_stream stream)} *)

let has_body message =
  Body.has_body message.body

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

type 'a global = {
  key : 'a Scope.key;
  initializer_ : unit -> 'a;
}

let new_global ?name ?show_value initializer_ = {
  key = Scope.Key.create (name, show_value);
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
    ~headers =

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
      upload = initial_multipart_state ();
    };
    headers;
    body = ref (`Stream (ref `Idle));
    locals = Scope.empty;
    first = request; (* TODO LATER What OCaml version is required for this? *)
    last = ref request;
  } in

  request

let request
    ?(client = "127.0.0.1:12345")
    ?(method_ = `GET)
    ?(target = "/")
    ?(version = 1, 1)
    ?(headers = [])
    body =

  (* This function is used for debugging, so it's fine to allocate a fake body
     and then immediately replace it. *)
  let path, query = Formats.from_target target in

  let body =
    if String.length body = 0 then
      `Empty
    else
      `String body
  in

  let rec request = {
    specific = {
      app = new_app ();
      client;
      method_;
      target;
      prefix = [];
      path = Formats.from_target_path path;
      query = Formats.from_form_urlencoded query;
      request_version = version;
      upload = initial_multipart_state ();
    };
    headers;
    body = ref body;
    locals = Scope.empty;
    first = request;
    last = ref request;
  } in

  request

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

  let body =
    if String.length body = 0 then
      `Empty
    else
      `String body
  in

  let rec response = {
    specific = {
      status;
      websocket = None;
    };
    headers;
    body = ref body;
    locals = Scope.empty;
    first = response;
    last = ref response;
  } in

  response

let respond
    ?status
    ?code
    ?headers
    body =

  response ?status ?code ?headers body
  |> Lwt.return

let stream ?status ?code ?headers f =
  let response =
    response ?status ?code ?headers ""
    |> with_stream
  in
  (* TODO Should set up an error handler for this. *)
  Lwt.async (fun () -> f response);
  Lwt.return response

let empty ?headers status =
  respond ?headers ~status ""

let not_found _ =
  respond ~status:`Not_Found ""

let websocket ?headers handler =
  let response = response ?headers ~status:`Switching_Protocols "" in
  let response =
    {response with specific =
      {response.specific with websocket = Some handler}}
  in
  Lwt.return response

let send ?(kind = `Text) message websocket =
  websocket.send kind message

let receive websocket =
  websocket.receive ()

let close_websocket websocket =
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

let encryption_secret request =
  List.hd request.specific.app.secrets

let decryption_secrets request =
  request.specific.app.secrets

let encrypt ?associated_data request plaintext =
  Cipher.encrypt
    (module Cipher.AEAD_AES_256_GCM)
    ?associated_data
    (encryption_secret request)
    plaintext

let decrypt ?associated_data request ciphertext =
  Cipher.decrypt
    (module Cipher.AEAD_AES_256_GCM)
    ?associated_data
    (decryption_secrets request)
    ciphertext

let infer_cookie_prefix prefix domain path secure =
  match prefix, domain, path, secure with
    | Some (Some `Host), _, _, _ -> "__Host-"
    | Some (Some `Secure), _, _, _ -> "__Secure-"
    | Some None, _, _, _ -> ""
    | None, None, Some "/", true -> "__Host-"
    | None, _, _, true -> "__Secure-"
    | None, _, _, _ -> ""

(* TODO Some actual performance in the implementation. *)
let cookie
    ?prefix:cookie_prefix
    ?decrypt:(decrypt_cookie = true)
    ?domain
    ?path
    ?secure
    name
    request =

  let path =
    match path with
    | Some path -> path
    | None -> Some (prefix request)
  in

  let secure =
    match secure with
    | Some secure -> secure
    | None -> https request
  in

  let cookie_prefix = infer_cookie_prefix cookie_prefix domain path secure in
  let name = cookie_prefix ^ name in
  let test = fun (name', _) -> name = name' in

  match all_cookies request |> List.find_opt test with
  | None -> None
  | Some (_, value) ->
    if not decrypt_cookie then
      Some value
    else
      match Formats.from_base64url value with
      | Error _ ->
        None
      | Ok value ->
        decrypt request value ~associated_data:("dream.cookie-" ^ name)

let set_cookie
    ?prefix:cookie_prefix
    ?encrypt:(encrypt_cookie = true)
    ?expires
    ?max_age
    ?domain
    ?path
    ?secure
    ?(http_only = true)
    ?(same_site = Some `Strict)
    name
    value
    request
    response =

  (* TODO Need the site prefix, not the subsite prefix! *)
  let path =
    match path with
    | Some path -> path
    | None -> Some (prefix request)
  in

  let secure =
    match secure with
    | Some secure -> secure
    | None -> https request
  in

  let cookie_prefix = infer_cookie_prefix cookie_prefix domain path secure in

  let name = cookie_prefix ^ name in

  let value =
    if encrypt_cookie then
      (* Give each cookie name a different associated data "space," effectively
         partitioning valid ciphertexts among the cookies. See also
         https://github.com/aantron/dream/issues/19#issuecomment-820250853. *)
      encrypt request value ~associated_data:("dream.cookie-" ^ name)
      |> Formats.to_base64url
    else
      value
  in

  let set_cookie =
    Formats.to_set_cookie
      ?expires ?max_age ?domain ?path ~secure ~http_only ?same_site name value
  in

  add_header "Set-Cookie" set_cookie response
