(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



let graphql context schema = fun request ->
  let%lwt body = Dream.body request in

  (* TODO Actual error checking, logging, response, etc. *)
  let query = Graphql_parser.parse body |> Result.get_ok in

  let%lwt context = context request in

  (* TODO ?variables *)
  (* TODO ?operation_name *)
  (* TODO Handle all the cases. *)
  match%lwt Graphql_lwt.Schema.execute schema context query with
  | Ok (`Response json) ->
    (* TODO Review JSON library choice. *)
    (* TODO Proper headers, etc. *)
    Yojson.Basic.to_string json
    |> Dream.respond
  | _ ->
    (* TODO Way more detail. *)
    Dream.respond ~status:`Internal_Server_Error ""
