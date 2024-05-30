(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Type abbreviations and modules used in defining the primary types *)

type 'a field_metadata = {
  name : string option;
  show_value : ('a -> string) option;
}
module Fields = Hmap.Make (struct type 'a t = 'a field_metadata end)



(* Messages (requests and responses) *)

type client = {
  mutable method_ : Method.method_;
  mutable target : string;
}

type server = {
  mutable status : Status.status;
  mutable websocket : (Stream.stream * Stream.stream) option;
}

type kind =
  | Request
  | Response

type 'a message = {
  kind : kind;
  specific : 'a;
  mutable headers : (string * string) list;
  mutable client_stream : Stream.stream;
  mutable server_stream : Stream.stream;
  mutable body : string Eio.Promise.or_exn option;
  mutable fields : Fields.t;
}

type request = client message
type response = server message



(* Functions of messages *)

type handler = request -> response
type middleware = handler -> handler



(* Requests *)

let request
    ?method_
    ?(target = "/")
    ?(headers = [])
    client_stream
    server_stream =

  let method_ =
    match (method_ :> Method.method_ option) with
    | None -> `GET
    | Some method_ -> method_
  in
  {
    kind = Request;
    specific = {
      method_;
      target;
    };
    headers;
    client_stream;
    server_stream;
    body = None;
    fields = Fields.empty;
  }

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let set_method_ request method_ =
  request.specific.method_ <- (method_ :> Method.method_)

let set_target request target =
  request.specific.target <- target



(* Responses *)

let response ?status ?code ?(headers = []) client_stream server_stream =
  let status =
    match status, code with
    | None, None -> `OK
    | Some status, _ -> (status :> Status.status)
    | None, Some code -> Status.int_to_status code
  in
  {
    kind = Response;
    specific = {
      status;
      websocket = None;
    };
    headers;
    client_stream;
    server_stream;
    body = None;
    fields = Fields.empty;
  }

let status response =
  response.specific.status

let set_status response status =
  response.specific.status <- status



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

let lowercase_headers message =
  let headers =
    message.headers
    |> List.map (fun (name, value) -> String.lowercase_ascii name, value)
  in
  message.headers <- headers



(* Whole-body access *)

let body message =
  match message.body with
  | Some body_promise ->
    Eio.Promise.await_exn body_promise
  | None ->
    let stream =
      match message.kind with
      | Request -> message.server_stream
      | Response -> message.client_stream
    in
    let body_promise = Stream.read_until_close stream in
    message.body <- Some body_promise;
    Eio.Promise.await_exn body_promise

let set_body message body =
  message.body <- Some (Eio.Promise.create_resolved (Ok body));
  match message.kind with
  | Request -> message.server_stream <- Stream.string body
  | Response -> message.client_stream <- Stream.string body

let set_content_length_headers message =
  (* TODO Restore.
  if has_header message "Content-Length" then
    ()
  else
    if has_header message "Transfer-Encoding" then
      ()
    else
      match message.body with
      | None ->
        add_header message "Transfer-Encoding" "chunked"
      | Some body_promise ->
        match Lwt.poll body_promise with
        | None ->
          add_header message "Transfer-Encoding" "chunked"
        | Some body ->
          let length = string_of_int (String.length body) in
          add_header message "Content-Length" length
  *)
  ignore message;
  assert false

let drop_content_length_headers message =
  drop_header message "Content-Length";
  drop_header message "Transfer-Encoding"



(* Streams *)

let read stream =
  Stream.read_convenience stream

let write stream chunk =
  (* TODO Restore.
  let promise, resolver = Lwt.wait () in
  let length = String.length chunk in
  let buffer = Bigstringaf.of_string ~off:0 ~len:length chunk in
  Stream.write
    stream
    buffer 0 length false true
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    ~exn:(fun exn -> Lwt.wakeup_later_exn resolver exn)
    (fun () -> Lwt.wakeup_later resolver ());
  promise
  *)
  ignore stream;
  ignore chunk;
  assert false

let flush stream =
  (* TODO Restore.
  let promise, resolver = Lwt.wait () in
  Stream.flush
    stream
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    ~exn:(fun exn -> Lwt.wakeup_later_exn resolver exn)
    (Lwt.wakeup_later resolver);
  promise
  *)
  ignore stream;
  assert false

let close stream =
  Stream.close stream 1000

let client_stream message =
  message.client_stream

let server_stream message =
  message.server_stream

let set_client_stream message client_stream =
  message.client_stream <- client_stream

let set_server_stream message server_stream =
  message.server_stream <- server_stream



let create_websocket response =
  let in_reader, in_writer = Stream.pipe ()
  and out_reader, out_writer = Stream.pipe () in
  let client_stream = Stream.stream out_reader in_writer
  and server_stream = Stream.stream in_reader out_writer in
  let websocket = (client_stream, server_stream) in
  response.specific.websocket <- Some websocket;
  websocket

let get_websocket response =
  response.specific.websocket

let close_websocket ?(code = 1000) (client_stream, server_stream) =
  Stream.close client_stream code;
  Stream.close server_stream code

type text_or_binary = [
  | `Text
  | `Binary
]

type end_of_message = [
  | `End_of_message
  | `Continues
]

let receive_fragment stream =
  (* TODO Restore.
  let promise, resolver = Lwt.wait () in
  let close _code = Lwt.wakeup_later resolver None in
  let abort exn = Lwt.wakeup_later_exn resolver exn in

  let rec loop () =
    Stream.read stream
      ~data:(fun buffer offset length binary fin ->
        let string =
          Bigstringaf.sub buffer ~off:offset ~len:length
          |> Bigstringaf.to_string
        in
        let text_or_binary = if binary then `Binary else `Text in
        let end_of_message = if fin then `End_of_message else `Continues in
        Lwt.wakeup_later
          resolver (Some (string, text_or_binary, end_of_message)))

      ~flush:loop

      ~ping:(fun buffer offset length ->
        Stream.pong stream buffer offset length ~close ~exn:abort loop)

      ~pong:(fun _buffer _offset _length ->
        loop ())

      ~close

      ~exn:abort
  in
  loop ();

  promise
  *)
  ignore stream;
  assert false

(* TODO This can be optimized by using a buffer, and also by immediately
   returning the first chunk without accumulation if FIN is set on it. *)
(* TODO Test what happens on end of stream without FIN set. The next read should
   still gracefully return None. *)
let receive_full stream =
  (* TODO Restore.
  let rec receive_continuations text_or_binary acc =
    match%lwt receive_fragment stream with
    | None ->
      Lwt.return (Some (acc, text_or_binary))
    | Some (fragment, _, `End_of_message) ->
      Lwt.return (Some (acc ^ fragment, text_or_binary))
    | Some (fragment, _, `Continues) ->
      receive_continuations text_or_binary (acc ^ fragment)
  in
  match%lwt receive_fragment stream with
  | None ->
    Lwt.return_none
  | Some (fragment, text_or_binary, `End_of_message) ->
    Lwt.return (Some (fragment, text_or_binary))
  | Some (fragment, text_or_binary, `Continues) ->
    receive_continuations text_or_binary fragment
  *)
  ignore stream;
  assert false

let receive stream =
  (* TODO Restore.
  match%lwt receive_full stream with
  | None -> Lwt.return_none
  | Some (message, _) -> Lwt.return (Some message)
  *)
  ignore receive_full;
  ignore stream;
  assert false

let send ?text_or_binary ?end_of_message stream data =
  (* TODO Restore.
  let promise, resolver = Lwt.wait () in
  let binary =
    match text_or_binary with
    | Some `Binary -> true
    | Some `Text -> false
    | None -> false
  in
  let fin =
    match end_of_message with
    | Some `End_of_message -> true
    | Some `Continues -> false
    | None -> true
  in
  let length = String.length data in
  let buffer = Bigstringaf.of_string ~off:0 ~len:length data in
  Stream.write
    stream buffer 0 length binary fin
    ~close:(fun _code -> Lwt.wakeup_later_exn resolver End_of_file)
    ~exn:(fun exn -> Lwt.wakeup_later_exn resolver exn)
    (fun () -> Lwt.wakeup_later resolver ());
  promise
  *)
  ignore text_or_binary;
  ignore end_of_message;
  ignore stream;
  ignore data;
  assert false



(* Middleware *)

let no_middleware handler request =
  handler request

let rec pipeline middlewares handler =
  match middlewares with
  | [] -> handler
  | middleware::more -> middleware (pipeline more handler)



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
