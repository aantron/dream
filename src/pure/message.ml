(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Type abbreviations and modules used in defining the primary types *)

type 'a promise = 'a Lwt.t

type 'a field_metadata = {
  name : string option;
  show_value : ('a -> string) option;
}
module Fields = Hmap.Make (struct type 'a t = 'a field_metadata end)



(* Messages (requests and responses) *)

type client = {
  mutable method_ : Method.method_;
  target : string;
  mutable version : int * int;
}
(* TODO Get rid of the version field completely? At least don't expose it in
   Dream. It is only used internally on the server side to add the right
   Content-Length, etc., headers. But even that can be moved out of the
   middleware and into transport so that the version field is not necessary for
   some middleware to decide which headers to add. *)

type server = {
  status : Status.status;
}

type 'a message = {
  specific : 'a;
  mutable headers : (string * string) list;
  mutable client_stream : Stream.stream;
  mutable server_stream : Stream.stream;
  mutable fields : Fields.t;
}

type request = client message
type response = server message



(* Functions of messages *)

type handler = request -> response Lwt.t
type middleware = handler -> handler



(* Requests *)

let request
    ?method_
    ?(target = "/")
    ?(version = 1, 1)
    ?(headers = [])
    client_stream
    server_stream =

  let method_ =
    match (method_ :> Method.method_ option) with
    | None -> `GET
    | Some method_ -> method_
  in
  {
    specific = {
      method_;
      target;
      version;
    };
    headers;
    client_stream;
    server_stream;
    fields = Fields.empty;
  }

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let version request =
  request.specific.version

let set_method_ request method_ =
  request.specific.method_ <- (method_ :> Method.method_)

let set_version request version =
  request.specific.version <- version



(* Responses *)

let response ?status ?code ?(headers = []) client_stream server_stream =
  let status =
    match status, code with
    | None, None -> `OK
    | Some status, _ -> (status :> Status.status)
    | None, Some code -> Status.int_to_status code
  in
  {
    specific = {
      status;
    };
    headers;
    client_stream;
    server_stream;
    fields = Fields.empty;
  }

let status response =
  response.specific.status



(* Headers *)

let header_basic name message =
  let name = String.lowercase_ascii name in
  message.headers
  |> List.find (fun (name', _) -> String.lowercase_ascii name' = name)
  |> snd

let header message name =
  try Some (header_basic name message)
  with Not_found -> None

let headers message name =
  let name = String.lowercase_ascii name in

  message.headers
  |> List.fold_left (fun matched (name', value) ->
    if String.lowercase_ascii name' = name then
      value::matched
    else
      matched)
    []
  |> List.rev

let all_headers message =
  message.headers

let has_header message name =
  try ignore (header_basic name message); true
  with Not_found -> false

let add_header message name value =
  message.headers <- message.headers @ [(name, value)]

(* TODO Can optimize this if the header is not found? *)
let drop_header message name =
  let name = String.lowercase_ascii name in
  message.headers <-
    message.headers
    |> List.filter (fun (name', _) -> String.lowercase_ascii name' <> name)

let set_header message name value =
  drop_header message name;
  add_header message name value

let set_all_headers message headers =
  message.headers <- headers

let sort_headers headers =
  List.stable_sort (fun (name, _) (name', _) -> compare name name') headers



(* Streams *)

let read message =
  Stream.read_convenience message.server_stream

(* TODO Need to expose FIN. However, it can't have any effect even on
   WebSockets, because websocket/af does not offer the ability to pass FIN. It
   is hardcoded to true. *)
(* TODO Also expose binary/text. What should be the default? *)
let write ?kind message chunk =
  let binary =
    match kind with
    | None | Some `Text -> false
    | Some `Binary -> true
  in
  let promise, resolver = Lwt.wait () in
  let length = String.length chunk in
  let buffer = Bigstringaf.of_string ~off:0 ~len:length chunk in
  (* TODO Better handling of close? But it can't even occur with http/af. *)
  Stream.write
    message.server_stream
    buffer 0 length binary true
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    (fun () -> Lwt.wakeup_later resolver ());
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

(* TODO Should close even be promise-valued? *)
let close ?(code = 1000) message =
  Stream.close message.server_stream code;
  Lwt.return_unit

let client_stream message =
  message.client_stream

let server_stream message =
  message.server_stream

let set_client_stream message client_stream =
  message.client_stream <- client_stream

let set_server_stream message server_stream =
  message.server_stream <- server_stream



(* Middleware *)

let no_middleware handler request =
  handler request

let rec pipeline middlewares handler =
  match middlewares with
  | [] -> handler
  | middleware::more -> middleware (pipeline more handler)
(* TODO Test pipelien after the List.rev fiasco. *)



(* Custom fields *)

type 'a field = 'a Fields.key

let new_field ?name ?show_value () =
  Fields.Key.create {name; show_value}

let field message key =
  Fields.find key message.fields

let set_field message key value =
  message.fields <- Fields.add key value message.fields

let fold_fields f initial message =
  Fields.fold (fun (B (key, value)) accumulator ->
    match Fields.Key.info key with
    | {name = Some name; show_value = Some show_value} ->
      f name (show_value value) accumulator
    | _ -> accumulator)
    message.fields
    initial



(* Whole-body access *)

(* TODO Show the value somehow. *)
let body_field : string promise field =
  new_field
    ~name:"dream.body"
    ()

(* TODO NOTE On the client, this will read the client stream until close. *)
let body message =
  match field message body_field with
  | Some body_promise -> body_promise
  | None ->
    let body_promise = Stream.read_until_close message.server_stream in
    set_field message body_field body_promise;
    body_promise

(* TODO Should usage of this function affect the body field? *)
(* TODO NOTE In Dream, this should operate on response server_streams. In Hyper,
   it should operate on request client_streams, although there is no very good
   reason why it can't operate on general messages, which might be useful in
   middlewares that preprocess requests on the server and postprocess responses
   on the client. Or.... shouldn't this affect the client stream on the server,
   replacing its read end? *)
let set_body message body =
  message.client_stream <- Stream.string body
