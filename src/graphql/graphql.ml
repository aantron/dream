(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let log =
  Dream__middleware.Log.sub_log "dream.graphql"

(* TODO Subscription support. *)

(* https://github.com/graphql/graphql-over-http/blob/main/spec/GraphQLOverHTTP.md *)
let graphql context schema = fun request ->
  let%lwt query, operation_name, variables =
    match Dream.method_ request with
    | `GET ->
      (* TODO Does OCaml graphql provide a way of limiting execution to only a
         query when under a GET request? Probably best to recommend putting
         this under POST routes only for now. *)
      let query = Dream.query "query" request
      and operation_name = Dream.query "operationName" request
      and variables =
        Dream.query "variables" request
        |> Option.map Yojson.Basic.from_string in
      (* TODO Proper error checking for that Yojson call. *)

      Lwt.return (query, operation_name, variables)

    | `POST ->
      begin match Dream.header "Content-Type" request with
      | Some "application/json" ->

        let%lwt body = Dream.body request in
        (* TODO This almost certainly raises exceptions... *)
        let json = Yojson.Basic.from_string body in

        let module Y = Yojson.Basic.Util in

        let query =
          json |> Y.member "query" |> Y.to_string_option
        and operation_name =
          json |> Y.member "operationName" |> Y.to_string_option
        and variables =
          json |> Y.member "variables" |> Option.some in

        Lwt.return (query, operation_name, variables)

      | _ ->
        log.warning (fun log -> log ~request
          "Content-Type not 'application/json'");
        (* TODO Could probably use more precise error handling. *)
        Lwt.return (None, None, None)
      end

    | method_ ->
      log.error (fun log -> log ~request
        "Method %s; must be GET or POST" (Dream.method_to_string method_));
      Lwt.return (None, None, None)
      (* TODO Ditto on the more precise error handling. *)
  in

  match query with
  | None ->
    log.warning (fun log -> log ~request "No query");
    Dream.empty `Bad_Request

  | Some query ->
    match Graphql_parser.parse query with
    | Error message ->
      log.warning (fun log -> log ~request "Query parser: %s" message);
      Dream.empty `Bad_Request
    | Ok query ->

      let%lwt context = context request in

      let variables =
        match variables with
        | Some (`Assoc _ as json) ->
          (Yojson.Basic.Util.to_assoc json :>
            (string * Graphql_parser.const_value) list)
          |> Option.some
        | _ ->
          None
      in

      let result_promise =
        Graphql_lwt.Schema.execute
          ?variables ?operation_name schema context query in

      match%lwt result_promise with
      | Ok (`Response json) ->
        Yojson.Basic.to_string json
        |> Dream.respond ~headers:["Content-Type", "application/json"]

      | Ok (`Stream _) ->
        (* TODO What is the meaning of `Stream, exactly? *)
        log.error (fun log -> log ~request "`Stream response not implemented");
        Dream.empty `Internal_Server_Error

      | Error json ->
        Yojson.Basic.to_string json
        |> Dream.respond
          ~status:`Bad_Request
          ~headers:["Content-Type", "application/json"]
