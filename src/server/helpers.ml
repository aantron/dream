(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Formats = Dream_pure.Formats
module Message = Dream_pure.Message
module Status = Dream_pure.Status
module Stream = Dream_pure.Stream



let client_field =
  Message.new_field
    ~name:"dream.client"
    ~show_value:(fun client -> client)
    ()

(* TODO What should be reported when the client address is missing? This is a
   sign of local testing. *)
let client request =
  match Message.field request client_field with
  | None -> "127.0.0.1:0"
  | Some client -> client

let set_client request client =
  Message.set_field request client_field client



let https_field =
  Message.new_field
    ~name:"dream.https"
    ~show_value:string_of_bool
    ()

let https request =
  match Message.field request https_field with
  | Some true -> true
  | _ -> false

let set_https request https =
  Message.set_field request https_field https



let request ~client ~method_ ~target ~https ~version ~headers server_stream =
  let request =
    Message.request
      ~method_ ~target ~version ~headers Stream.null server_stream in
  set_client request client;
  set_https request https;
  request

let request_with_body ?method_ ?target ?version ?headers body =
  Message.request
    ?method_ ?target ?version ?headers Stream.null (Stream.string body)



let html ?status ?code ?headers body =
  let response =
    Message.response ?status ?code ?headers (Stream.string body) Stream.null in
  Message.set_header response "Content-Type" Formats.text_html;
  Lwt.return response

let json ?status ?code ?headers body =
  let response =
    Message.response ?status ?code ?headers (Stream.string body) Stream.null in
  Message.set_header response "Content-Type" Formats.application_json;
  Lwt.return response

let response_with_body ?status ?code ?headers body =
  Message.response ?status ?code ?headers (Stream.string body) Stream.null

let respond ?status ?code ?headers body =
  Message.response ?status ?code ?headers (Stream.string body) Stream.null
  |> Lwt.return

(* TODO Actually use the request and extract the site prefix. *)
let redirect ?status ?code ?headers _request location =
  let status = (status :> Status.redirection option) in
  let status =
    match status, code with
    | None, None -> Some (`See_Other)
    | _ -> status
  in
  let response =
    Message.response ?status ?code ?headers Stream.empty Stream.null in
  Message.set_header response "Location" location;
  Lwt.return response

let stream ?status ?code ?headers callback =
  let reader, writer = Stream.pipe () in
  let client_stream = Stream.stream reader Stream.no_writer
  and server_stream = Stream.stream Stream.no_reader writer in
  let response =
    Message.response ?status ?code ?headers client_stream server_stream in
  (* TODO Should set up an error handler for this. YES. *)
  (* TODO Make sure the request id is propagated to the callback. *)
  Lwt.async (fun () -> callback response);
  Lwt.return response

(* TODO Mark the request as a WebSocket request for HTTP. *)
let websocket ?headers callback =
  let response =
    Message.response
      ~status:`Switching_Protocols ?headers Stream.empty Stream.null in
  let server_stream = Message.create_websocket response in
  (* TODO Figure out what should actually be returned to the client and/or
     provided to the callback. Probably the server stream. The surface API for
     WebSockets also needs to be designed. *)
  ignore server_stream;
  (* TODO Make sure the request id is propagated to the callback. *)
  (* TODO Close the WwbSocket on leaked exceptions, etc. *)
  Lwt.async (fun () -> callback response);
  Lwt.return response

let empty ?headers status =
  respond ?headers ~status ""

let not_found _ =
  respond ~status:`Not_Found ""



(* TODO Once the WebSocket API exists, these functions should not check whether
   the message has a WebSocket. *)
let read message =
  match Message.get_websocket message with
  | None ->
    Message.read (Message.server_stream message)
  | Some (_client_stream, server_stream) ->
    Message.read server_stream

let write ?kind message chunk =
  match Message.get_websocket message with
  | None ->
    Message.write ?kind (Message.server_stream message) chunk
  | Some (_client_stream, server_stream) ->
    Message.write ?kind server_stream chunk

let flush message =
  match Message.get_websocket message with
  | None ->
    Message.flush (Message.server_stream message)
  | Some (_client_stream, server_stream) ->
    Message.flush server_stream

let close ?(code = 1000) message =
  match Message.get_websocket message with
  | None ->
    Message.close message
  | Some (_client_stream, server_stream) ->
    Stream.close server_stream code;
    Lwt.return_unit
