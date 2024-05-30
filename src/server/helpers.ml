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



let tls_field =
  Message.new_field
    ~name:"dream.tls"
    ~show_value:string_of_bool
    ()

let tls request =
  match Message.field request tls_field with
  | Some true -> true
  | _ -> false

let set_tls request tls =
  Message.set_field request tls_field tls



let request ~client ~method_ ~target ~tls ~headers server_stream =
  let request =
    Message.request ~method_ ~target ~headers Stream.null server_stream in
  set_client request client;
  set_tls request tls;
  request

let request_with_body ?method_ ?target ?headers body =
  Message.request ?method_ ?target ?headers Stream.null (Stream.string body)



let response_with_body ?status ?code ?headers body =
  let response =
    Message.response ?status ?code ?headers Stream.null Stream.null in
  Message.set_body response body;
  response

let respond ?status ?code ?headers body =
  response_with_body ?status ?code ?headers body

let html ?status ?code ?headers body =
  let response = response_with_body ?status ?code ?headers body in
  Message.set_header response "Content-Type" Formats.text_html;
  response

let json ?status ?code ?headers body =
  let response = response_with_body ?status ?code ?headers body in
  Message.set_header response "Content-Type" Formats.application_json;
  response

(* TODO Actually use the request and extract the site prefix. *)
let redirect ?status ?code ?headers _request location =
  let status = (status :> Status.redirection option) in
  let status =
    match status, code with
    | None, None -> Some (`See_Other)
    | _ -> status
  in
  let response = response_with_body ?status ?code ?headers "" in
  Message.set_header response "Location" location;
  response

let stream ?status ?code ?headers ?(close = true) callback =
  let reader, writer = Stream.pipe () in
  let client_stream = Stream.stream reader Stream.no_writer
  and server_stream = Stream.stream Stream.no_reader writer in
  let response =
    Message.response ?status ?code ?headers client_stream server_stream in

  (* TODO Make sure the request id is propagated to the callback. *)
  (* TODO This needs to become a fiber, or to be called afterwards in the
     current fiber, after having Cohttp start the response -- depends on the
     semantics of Cohttp.
  Lwt.async (fun () ->
    if close then
      match%lwt callback server_stream with
      | () ->
        Message.close server_stream
      | exception exn ->
        let%lwt () = Message.close server_stream in
        raise exn
    else
      callback server_stream);
  *)
  ignore close;
  ignore callback;

  response

let empty ?headers status =
  respond ?headers ~status ""

let not_found _ =
  respond ~status:`Not_Found ""



let websocket ?headers ?(close = true) callback =
  let response =
    Message.response
      ~status:`Switching_Protocols ?headers Stream.empty Stream.null in
  let websocket = Message.create_websocket response in

  (* TODO Make sure the request id is propagated to the callback. *)
  (* TODO Get this working, depending on the semantics of Cohttp.
  Lwt.async (fun () ->
    if close then
      match%lwt callback websocket with
      | () ->
        Message.close_websocket websocket
      | exception exn ->
        let%lwt () = Message.close_websocket websocket ~code:1005 in
        raise exn
    else
      callback websocket);
  *)
  ignore websocket;
  ignore callback;
  ignore close;

  response

let receive (_, server_stream) =
  Message.receive server_stream

let receive_fragment (_, server_stream) =
  Message.receive_fragment server_stream

let send ?text_or_binary ?end_of_message (_, server_stream) data =
  Message.send ?text_or_binary ?end_of_message server_stream data
