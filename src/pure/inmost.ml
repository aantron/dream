(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type method_ = Method.method_
type status = Status.status

type stream = Stream.stream
type buffer = Stream.buffer

module Custom_field_metadata =
struct
  type 'a t = string option * ('a -> string) option
end
module Fields = Hmap.Make (Custom_field_metadata)

type request = client message
and response = server message

and 'a message = {
  specific : 'a;
  mutable headers : (string * string) list;
  mutable client_stream : Stream.stream;
  mutable server_stream : Stream.stream;
  mutable fields : Fields.t;
}

and client = {
  mutable method_ : method_;
  target : string;
  mutable request_version : int * int;
}
(* TODO Get rid of the version field completely? At least don't expose it in
   Dream. It is only used internally on the server side to add the right
   Content-Length, etc., headers. But even that can be moved out of the
   middleware and into transport so that the version field is not necessary for
   some middleware to decide which headers to add. *)

and server = {
  status : status;
}

type 'a promise = 'a Lwt.t

type handler = request -> response Lwt.t
type middleware = handler -> handler

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let version request =
  request.specific.request_version

let set_method_ request method_ =
  request.specific.method_ <- (method_ :> method_)

let set_version request version =
  request.specific.request_version <- version

let status response =
  response.specific.status

let all_headers message =
  message.headers

let set_all_headers message headers =
  message.headers <- headers

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

let header_basic name message =
  let name = String.lowercase_ascii name in
  message.headers
  |> List.find (fun (name', _) -> String.lowercase_ascii name' = name)
  |> snd

let header message name =
  try Some (header_basic name message)
  with Not_found -> None

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

(* TODO NOTE On the client, this will read the client stream until close. *)
let body message =
  Stream.read_until_close message.server_stream

let read message =
  Stream.read_convenience message.server_stream

let client_stream message =
  message.client_stream

let server_stream message =
  message.server_stream

let set_client_stream message client_stream =
  message.client_stream <- client_stream

let set_server_stream message server_stream =
  message.server_stream <- server_stream

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
let set_body message body =
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
  message.server_stream <- body

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



type 'a field = 'a Fields.key

let new_field ?name ?show_value () =
  Fields.Key.create (name, show_value)

let field message key =
  Fields.find key message.fields

let set_field message key value =
  message.fields <- Fields.add key value message.fields

let fold_fields f initial message =
  Fields.fold (fun (B (key, value)) accumulator ->
    match Fields.Key.info key with
    | Some name, Some show_value -> f name (show_value value) accumulator
    | _ -> accumulator)
    message.fields
    initial



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

  {
    specific = {
      (* TODO Is there a better fake error handler? Maybe this function should
         come after the response constructors? *)
      method_;
      target;
      request_version = version;
    };
    headers;
    client_stream;
    server_stream;
    fields = Fields.empty;
  }

let response
    ?status ?code ?(headers = []) client_stream server_stream =

  let status =
    match status, code with
    | None, None -> `OK
    | Some status, _ -> (status :> status)
    | None, Some code -> Status.int_to_status code
  in

  {
    specific = {
      status;
    };
    headers;
    client_stream;
    server_stream;
    (* TODO This fully dead stream should be preallocated. *)
    fields = Fields.empty;
  }

let no_middleware handler request =
  handler request

let rec pipeline middlewares handler =
  match middlewares with
  | [] -> handler
  | middleware::more -> middleware (pipeline more handler)
(* TODO Test pipelien after the List.rev fiasco. *)

let sort_headers headers =
  List.stable_sort (fun (name, _) (name', _) -> compare name name') headers
