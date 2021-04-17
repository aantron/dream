(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* This GraphQL handler supports two transports, i.e. two GraphQL "wire"
   protocols:

   - HTTP requests/responses for queries and mutations. See

       https://github.com/graphql/graphql-over-http/blob/main/spec/GraphQLOverHTTP.md

   - WebSockets for queries, mutations, and subscriptions. See

       https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md *)

let log =
  Dream__middleware.Log.sub_log "dream.graphql"



(* Shared between HTTP and WebSocket transport. *)

let make_error message =
  `Assoc [
    "errors", `Assoc [
      "message", `String message
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

  (* TODO Parse errors should likely be returned to the client. *)
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

  (* TODO Consider passing the variables and operation name to the
     context-maker. *)
  let%lwt context = make_context request in

  Graphql_lwt.Schema.execute
    ?variables ?operation_name schema context query



(* WebSocket transport. *)

(* TODO Refuse second connection_init. *)
(* TODO Close WebSocket with the right status codes. Is this even
   exposed upstream? *)

let operation_id json =
  Yojson.Basic.Util.(json |> member "id" |> to_string_option)

let close_and_clean subscriptions websocket =
  match%lwt Dream.close_websocket websocket with
  | _ ->
    Hashtbl.iter (fun _ close -> close ()) subscriptions;
    Lwt.return_unit
  | exception _ ->
    Hashtbl.iter (fun _ close -> close ()) subscriptions;
    Lwt.return_unit

let connection_message type_ =
  `Assoc [
    "type", `String type_;
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

(* TODO What should be passed for creating the context for WebSocket
   transport? *)
(* TODO Once WebSocket streaming is properly supported, outgoing messages must
   be split into frames. Also, should there be a limit on incoming message
   size? *)
(* TODO Take care to pass around the request Lwt.key in async, etc. *)
let handle_over_websocket make_context schema subscriptions request websocket =
  let rec loop () =
    match%lwt Dream.receive websocket with
    | None ->
      log.info (fun log -> log ~request "GraphQL WebSocket closed by client");
      close_and_clean subscriptions websocket
    | Some message ->

    log.debug (fun log -> log ~request "Message '%s'" message);

    (* TODO Avoid using exceptions here. *)
    match Yojson.Basic.from_string message with
    | exception _ ->
      log.warning (fun log -> log ~request "GraphQL message is not JSON");
      close_and_clean subscriptions websocket
    | json ->

    match Yojson.Basic.Util.(json |> member "type" |> to_string_option) with
    | None ->
      log.warning (fun log -> log  ~request "GraphQL message lacks a type");
      close_and_clean subscriptions websocket
    | Some message_type ->

    match message_type with
    | "connection_init" ->
      let%lwt () = Dream.send (connection_message "connection_ack") websocket in
      loop ()

    | "complete" ->
      begin match operation_id json with
      | None ->
        log.warning (fun log ->
          log ~request "client complete: operation id missing");
        close_and_clean subscriptions websocket
      | Some id ->
        begin match Hashtbl.find_opt subscriptions id with
        | None -> ()
        | Some close -> close ()
        end;
        loop ()
      end

    | "subscribe" ->
      begin match operation_id json with
      | None ->
        log.warning (fun log -> log ~request "subscribe: operation id missing");
        close_and_clean subscriptions websocket
      | Some id ->

        let payload = json |> Yojson.Basic.Util.member "payload" in

        Lwt.async begin fun () ->
          try%lwt
            match%lwt run_query make_context schema request payload with
            | Error json ->
              log.warning (fun log ->
                log ~request
                  "subscribe: error %s" (Yojson.Basic.to_string json));
              let%lwt () = Dream.send (error_message id json) websocket in
              loop ()

            (* It's not clear that this case ever occurs, because graphql-ws is
               only used for subscriptions, at the protocol level. *)
            | Ok (`Response json) ->
              let%lwt () = Dream.send (data_message id json) websocket in
              let%lwt () = Dream.send (complete_message id) websocket in
              loop ()

            | Ok (`Stream (stream, close)) ->
              match Hashtbl.mem subscriptions id with
              | true ->
                log.warning (fun log ->
                  log ~request "subscribe: duplicate operation id");
                close_and_clean subscriptions websocket
              | false ->

              Hashtbl.add subscriptions id close;

              let%lwt () =
                stream |> Lwt_stream.iter_s (function
                  | Ok json ->
                    Dream.send (data_message id json) websocket
                  | Error json ->
                    log.warning (fun log ->
                      log ~request
                        "Subscription: error %s" (Yojson.Basic.to_string json));
                    Dream.send (error_message id json) websocket)
              in

              Dream.send (complete_message id) websocket

            with exn ->
              log.error (fun log ->
                log ~request "Exception while handling WebSocket message:");
              log.error (fun log ->
                log ~request "%s" (Printexc.to_string exn));
              Printexc.get_backtrace ()
              |> Dream__middleware.Log.iter_backtrace (fun line ->
                log.error (fun log -> log ~request "%s" line));

              try%lwt close_and_clean subscriptions websocket
              with _ -> Lwt.return_unit
          end;

        loop ()
      end

    | message_type ->
      log.warning (fun log ->
        log ~request "Unknown WebSocket message type '%s'" message_type);
      loop ()
  in

  loop ()



(* HTTP transport.

   Supports either POST requests carrying a GraphQL query, or GET requests
   carrying WebSocket upgrade headers. *)

(* TODO How to do some kind of client verification for WebSocket requests, given
   that the method is GET? *)
(* TODO A lot of Bad_Request responses should become Not_Found to leak less
   info. Or 200 OK? *)
(* TODO Check the sub-protocol. *)
(* TODO Add ~headers to Dream.websocket. *)
let graphql make_context schema = fun request ->
  match Dream.method_ request with
  | `GET ->
    begin match Dream.header "Upgrade" request with
    | Some "websocket" ->
      let%lwt response =
        Dream.websocket
          (handle_over_websocket
            make_context schema (Hashtbl.create 16) request) in
      response
      |> Dream.add_header "Sec-WebSocket-Protocol" "graphql-transport-ws"
      |> Lwt.return
    | _ ->
      log.warning (fun log -> log ~request "Upgrade: websocket header missing");
      Dream.empty `Bad_Request
    end

  | `POST ->
    begin match Dream.header "Content-Type" request with
    | Some "application/json" ->
      let%lwt body = Dream.body request in
      (* TODO This almost certainly raises exceptions... *)
      let json = Yojson.Basic.from_string body in

      begin match%lwt run_query make_context schema request json with
      | Error json ->
        Yojson.Basic.to_string json
        |> Dream.respond ~headers:["Content-Type", "application/json"]

      | Ok (`Response json) ->
        Yojson.Basic.to_string json
        |> Dream.respond ~headers:["Content-Type", "application/json"]

      | Ok (`Stream _) ->
        make_error "Subscriptions and streaming should use WebSocket transport"
        |> Yojson.Basic.to_string
        |> Dream.respond ~headers:["Content-Type", "application/json"]
      end

    | _ ->
      log.warning (fun log -> log ~request
        "Content-Type not 'application/json'");
      Dream.empty `Bad_Request
    end

  | method_ ->
    log.error (fun log -> log ~request
      "Method %s; must be GET or POST" (Dream.method_to_string method_));
    Dream.empty `Bad_Request



(* TODO May want to escape the endpoint string. *)
let graphiql graphql_endpoint =
  let html =
    lazy begin
      Dream__graphiql.content
      |> Str.(global_replace (regexp (quote "%%ENDPOINT%%")) graphql_endpoint)
    end
  in

  fun _request ->
    Dream.respond (Lazy.force html)
