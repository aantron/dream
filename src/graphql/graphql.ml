(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Helpers = Dream__server.Helpers
module Log = Dream__server.Log
module Message = Dream_pure.Message
module Method = Dream_pure.Method
module Stream = Dream_pure.Stream



(* This GraphQL handler supports two transports, i.e. two GraphQL "wire"
   protocols:

   - HTTP requests/responses for queries and mutations. See

       https://github.com/graphql/graphql-over-http/blob/main/spec/GraphQLOverHTTP.md

   - WebSockets for queries, mutations, and subscriptions. See

       https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md *)

let log =
  Log.sub_log "dream.graphql"



(* Shared between HTTP and WebSocket transport. *)

let make_error message =
  `Assoc [
    "errors", `List [
      `Assoc [
        "message", `String message
      ]
    ]
  ]

let run_query make_context schema request json =
  let module Y = Yojson.Basic.Util in

  let query =          json |> Y.member "query" |> Y.to_string_option
  and operation_name = json |> Y.member "operationName" |> Y.to_string_option
  and variables =      json |> Y.member "variables" |> Option.some in

  match query with
  | None -> Lwt.return (Error (make_error "No query"))
  | Some query ->

  match Graphql_parser.parse query with
  | Error message -> Lwt.return (Error (make_error message))
  | Ok query ->

  (* TODO Consider being more strict here, allowing only `Assoc and `Null. *)
  let variables =
    match variables with
    | Some (`Assoc _ as json) ->
      (Yojson.Basic.Util.to_assoc json :>
        (string * Graphql_parser.const_value) list)
      |> Option.some
    | _ ->
      None
  in

  let%lwt context = make_context request in

  Graphql_lwt.Schema.execute
    ?variables ?operation_name schema context query



(* WebSocket transport. *)

let operation_id json =
  Yojson.Basic.Util.(json |> member "id" |> to_string_option)

let close_and_clean ?code subscriptions response =
  let%lwt () = Message.close ?code response in
  Hashtbl.iter (fun _ close -> close ()) subscriptions;
  Lwt.return_unit

let ack_message =
  `Assoc [
    "type", `String "connection_ack";
  ]
  |> Yojson.Basic.to_string

let data_message id payload =
  `Assoc [
    "type", `String "next";
    "id", `String id;
    "payload", payload;
  ]
  |> Yojson.Basic.to_string

let error_message id json =
  `Assoc [
    "type", `String "error";
    "id", `String id;
    "payload", json |> Yojson.Basic.Util.member "errors";
  ]
  |> Yojson.Basic.to_string

let complete_message id =
  `Assoc [
    "type", `String "complete";
    "id", `String id;
  ]
  |> Yojson.Basic.to_string

(* TODO Take care to pass around the request Lwt.key in async, etc. *)
(* TODO Test client complete racing against a stream. *)
let handle_over_websocket make_context schema subscriptions request response =
  Lwt_eio.Promise.await_lwt @@
  let rec loop inited =
    match%lwt Message.read response with
    | None ->
      log.info (fun log -> log ~request "GraphQL WebSocket closed by client");
      close_and_clean subscriptions response
    | Some message ->

    log.debug (fun log -> log ~request "Message '%s'" message);

    (* TODO Avoid using exceptions here. *)
    match Yojson.Basic.from_string message with
    | exception _ ->
      log.warning (fun log -> log ~request "GraphQL message is not JSON");
      close_and_clean subscriptions response ~code:4400
    | json ->

    match Yojson.Basic.Util.(json |> member "type" |> to_string_option) with
    | None ->
      log.warning (fun log -> log ~request "GraphQL message lacks a type");
      close_and_clean subscriptions response ~code:4400
    | Some message_type ->

    match message_type with

    | "connection_init" ->
      if inited then begin
        log.warning (fun log -> log ~request "Duplicate connection_init");
        close_and_clean subscriptions response ~code:4429
      end
      else begin
        let%lwt () = Message.write response ack_message in
        loop true
      end

    | "complete" ->
      if not inited then begin
        log.warning (fun log -> log ~request "complete before connection_init");
        close_and_clean subscriptions response ~code:4401
      end
      else begin
        match operation_id json with
        | None ->
          log.warning (fun log ->
            log ~request "client complete: operation id missing");
          close_and_clean subscriptions response ~code:4400
        | Some id ->
          begin match Hashtbl.find_opt subscriptions id with
          | None -> ()
          | Some close -> close ()
          end;
          loop inited
      end

    | "subscribe" ->
      if not inited then begin
        log.warning (fun log ->
          log ~request "subscribe before connection_init");
        close_and_clean subscriptions response ~code:4401
      end
      else begin
        match operation_id json with
        | None ->
          log.warning (fun log ->
            log ~request "subscribe: operation id missing");
          close_and_clean subscriptions response ~code:4400
        | Some id ->

        let payload = json |> Yojson.Basic.Util.member "payload" in

        Lwt.async begin fun () ->
          let subscribed = ref false in

          try%lwt
            match%lwt run_query make_context schema request payload with
            | Error json ->
              log.warning (fun log ->
                log ~request
                  "subscribe: error %s" (Yojson.Basic.to_string json));
              Message.write response (error_message id json)

            (* It's not clear that this case ever occurs, because graphql-ws is
               only used for subscriptions, at the protocol level. *)
            | Ok (`Response json) ->
              let%lwt () = Message.write response (data_message id json) in
              let%lwt () = Message.write response (complete_message id) in
              Lwt.return_unit

            | Ok (`Stream (stream, close)) ->
              match Hashtbl.mem subscriptions id with
              | true ->
                log.warning (fun log ->
                  log ~request "subscribe: duplicate operation id");
                close_and_clean subscriptions response ~code:4409
              | false ->

              Hashtbl.replace subscriptions id close;
              subscribed := true;

              let%lwt () =
                stream |> Lwt_stream.iter_s (function
                  | Ok json ->
                    Message.write response (data_message id json)
                  | Error json ->
                    log.warning (fun log ->
                      log ~request
                        "Subscription: error %s" (Yojson.Basic.to_string json));
                    Message.write response (error_message id json))
              in

              let%lwt () = Message.write response (complete_message id) in
              Hashtbl.remove subscriptions id;
              Lwt.return_unit

          with exn ->
            let backtrace = Printexc.get_backtrace () in
            log.error (fun log ->
              log ~request "Exception while handling WebSocket message:");
            log.error (fun log ->
              log ~request "%s" (Printexc.to_string exn));
            backtrace
            |> Log.iter_backtrace (fun line ->
              log.error (fun log -> log ~request "%s" line));

            try%lwt
              let%lwt () =
                Message.write
                  response
                  (error_message id (make_error "Internal Server Error"))
              in
              if !subscribed then
                Message.write response (complete_message id)
              else
                Lwt.return_unit
            with _ ->
              Lwt.return_unit
          end;

        loop inited
      end

    | message_type ->
      log.warning (fun log ->
        log ~request "Unknown WebSocket message type '%s'" message_type);
      close_and_clean subscriptions response ~code:4400
  in

  loop false



(* HTTP transport.

   Supports either POST requests carrying a GraphQL query, or GET requests
   carrying WebSocket upgrade headers. *)

let graphql make_context schema = fun request ->
  match Message.method_ request with
  | `GET ->
    let upgrade = Message.header request "Upgrade"
    and protocol = Message.header request "Sec-WebSocket-Protocol" in
    begin match upgrade, protocol with
    | Some "websocket", Some "graphql-transport-ws" ->
      Helpers.websocket
        ~headers:["Sec-WebSocket-Protocol", "graphql-transport-ws"]
        request
        (handle_over_websocket make_context schema (Hashtbl.create 16) request)
    | _ ->
      log.warning (fun log -> log ~request "Upgrade: websocket header missing");
      Message.response ~status:`Not_Found Stream.empty Stream.null
    end

  | `POST ->
    begin match Message.header request "Content-Type" with
    | Some "application/json" ->
      Lwt_eio.Promise.await_lwt (
        let%lwt body = Message.body request in
        (* TODO This almost certainly raises exceptions... *)
        let json = Yojson.Basic.from_string body in

        begin match%lwt run_query make_context schema request json with
          | Error json ->
            Yojson.Basic.to_string json
            |> Helpers.json
            |> Lwt.return

          | Ok (`Response json) ->
            Yojson.Basic.to_string json
            |> Helpers.json
            |> Lwt.return

          | Ok (`Stream _) ->
            make_error "Subscriptions and streaming should use WebSocket transport"
            |> Yojson.Basic.to_string
            |> Helpers.json
            |> Lwt.return
        end
      )

    | _ ->
      log.warning (fun log -> log ~request
        "Content-Type not 'application/json'");
      Message.response ~status:`Bad_Request Stream.empty Stream.null
    end

  | method_ ->
    log.error (fun log -> log ~request
      "Method %s; must be GET or POST" (Method.method_to_string method_));
    Message.response ~status:`Not_Found Stream.empty Stream.null



let graphiql ?(default_query = "") graphql_endpoint =
  begin match String.index_opt graphql_endpoint '"' with
  | None -> ()
  | Some _ ->
    log.error (fun log ->
      log "GraphQL endpoint route '%s' contains '\"'" graphql_endpoint);
    log.error (fun log ->
      log "If intentional, please open an issue about supporting this");
    log.error (fun log ->
      log "https://github.com/aantron/dream/issues")
  end;

  let html =
    lazy begin
      Dream__graphiql.content
      |> Str.(global_replace (regexp (quote "%%ENDPOINT%%")) graphql_endpoint)
      |> Str.(global_replace (regexp (quote "%%DEFAULT_QUERY%%")) default_query)
    end
  in

  fun _request ->
    Helpers.html (Lazy.force html)
