(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let graphql context schema = fun request ->
  let open Lwt.Infix in

  Dream.body request
  >>= fun body ->

  prerr_endline "body";

  (* TODO Actual error checking, logging, response, etc. *)
  let query = Graphql_parser.parse body |> Result.get_ok in

  context request
  >>= fun context ->

  (* TODO ?variables *)
  (* TODO ?operation_name *)
  Graphql_lwt.Schema.execute schema context query
  >>= fun graphql_response ->

  (* TODO Handle all the cases. *)
  match graphql_response with
  | Ok (`Response json) ->
    (* TODO Review JSON library choice. *)
    (* TODO Proper headers, etc. *)
    Yojson.Basic.to_string json
    |> Dream.respond
  | _ ->
    (* TODO Way more detail. *)
    Dream.respond ~status:`Internal_Server_Error ""
