(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure



let client_variable =
  Dream.new_local
    ~name:"dream.client"
    ~show_value:(fun client -> client)
    ()

(* TODO What should be reported when the client address is missing? This is a
   sign of local testing. *)
let client request =
  match Dream.local request client_variable with
  | None -> "127.0.0.1:0"
  | Some client -> client

let set_client request client =
  Dream.set_local request client_variable client



let https_variable =
  Dream.new_local
    ~name:"dream.https"
    ~show_value:string_of_bool
    ()

let https request =
  match Dream.local request https_variable with
  | Some true -> true
  | _ -> false

let set_https request https =
  Dream.set_local request https_variable https



let request ~client ~method_ ~target ~https ~version ~headers server_stream =
  (* TODO Use pre-allocated streams. *)
  let client_stream = Dream.Stream.(stream no_reader no_writer) in
  let request =
    Dream.request
      ~method_ ~target ~version ~headers client_stream server_stream in
  set_client request client;
  set_https request https;
  request



let html ?status ?code ?headers body =
  (* TODO The streams. *)
  let client_stream = Dream.Stream.(stream (string body) no_writer)
  and server_stream = Dream.Stream.(stream no_reader no_writer) in
  let response =
    Dream.response ?status ?code ?headers client_stream server_stream in
  Dream.set_header response "Content-Type" Dream.Formats.text_html;
  Lwt.return response

let json ?status ?code ?headers body =
  (* TODO The streams. *)
  let client_stream = Dream.Stream.(stream (string body) no_writer)
  and server_stream = Dream.Stream.(stream no_reader no_writer) in
  let response =
    Dream.response ?status ?code ?headers client_stream server_stream in
  Dream.set_header response "Content-Type" Dream.Formats.application_json;
  Lwt.return response
