(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO Long-term, query string handler is likely to become part of the
   router. *)

module Formats = Dream_pure.Formats
module Message = Dream_pure.Message



(* TODO Actually cache the result of parsing the query string. *)
(* let query_variable : (string * string) list Dream.local =
  Dream.new_local
    ~name:"dream.query"
    ~show_value:(fun query ->
      query
      |> List.map (fun (name, value) -> Printf.sprintf "%s=%s" name value)
      |> String.concat ", ") *)

let all_queries request =
  Message.target request
  |> Formats.split_target
  |> snd
  |> Formats.from_form_urlencoded

let query request name =
  List.assoc_opt name (all_queries request)

let queries request name =
  all_queries request
  |> List.fold_left (fun accumulator (name', value) ->
    if name' = name then
      value::accumulator
    else
      accumulator)
    []
  |> List.rev
