(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost
module Formats = Dream_pure.Formats
module Status = Dream_pure.Status
module Stream = Dream_pure.Stream



let client_field =
  Dream.new_field
    ~name:"dream.client"
    ~show_value:(fun client -> client)
    ()

(* TODO What should be reported when the client address is missing? This is a
   sign of local testing. *)
let client request =
  match Dream.field request client_field with
  | None -> "127.0.0.1:0"
  | Some client -> client

let set_client request client =
  Dream.set_field request client_field client



let https_field =
  Dream.new_field
    ~name:"dream.https"
    ~show_value:string_of_bool
    ()

let https request =
  match Dream.field request https_field with
  | Some true -> true
  | _ -> false

let set_https request https =
  Dream.set_field request https_field https



let request ~client ~method_ ~target ~https ~version ~headers server_stream =
  (* TODO Use pre-allocated streams. *)
  let client_stream = Stream.(stream no_reader no_writer) in
  let request =
    Dream.request
      ~method_ ~target ~version ~headers client_stream server_stream in
  set_client request client;
  set_https request https;
  request

let request_with_body ?method_ ?target ?version ?headers body =
  (* TODO Streams. *)
  let client_stream = Stream.(stream no_reader no_writer)
  and server_stream = Stream.(stream (string body) no_writer) in
  Dream.request ?method_ ?target ?version ?headers client_stream server_stream



let html ?status ?code ?headers body =
  (* TODO The streams. *)
  let client_stream = Stream.(stream (string body) no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  let response =
    Dream.response ?status ?code ?headers client_stream server_stream in
  Dream.set_header response "Content-Type" Formats.text_html;
  Lwt.return response

let json ?status ?code ?headers body =
  (* TODO The streams. *)
  let client_stream = Stream.(stream (string body) no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  let response =
    Dream.response ?status ?code ?headers client_stream server_stream in
  Dream.set_header response "Content-Type" Formats.application_json;
  Lwt.return response

let response_with_body ?status ?code ?headers body =
  (* TODO Streams. *)
  let client_stream = Stream.(stream (string body) no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  Dream.response ?status ?code ?headers client_stream server_stream

let respond ?status ?code ?headers body =
  let client_stream = Stream.(stream (string body) no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  Dream.response ?status ?code ?headers client_stream server_stream
  |> Lwt.return

(* TODO Actually use the request and extract the site prefix. *)
let redirect ?status ?code ?headers _request location =
  let status = (status :> Status.redirection option) in
  let status =
    match status, code with
    | None, None -> Some (`See_Other)
    | _ -> status
  in
  (* TODO The streams. *)
  let client_stream = Stream.(stream empty no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  let response =
    Dream.response ?status ?code ?headers client_stream server_stream in
  Dream.set_header response "Location" location;
  Lwt.return response

let stream ?status ?code ?headers f =
  (* TODO Streams. *)
  let client_stream = Stream.(stream empty no_writer)
  and server_stream = Stream.(stream no_reader no_writer) in
  let response =
    Dream.response ?status ?code ?headers client_stream server_stream in
  Dream.set_stream response;
  (* TODO Should set up an error handler for this. *)
  Lwt.async (fun () -> f response);
  Lwt.return response

let empty ?headers status =
  respond ?headers ~status ""

let not_found _ =
  respond ~status:`Not_Found ""
