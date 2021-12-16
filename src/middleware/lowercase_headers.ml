(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure



(* TODO This middleware might need to be applied right in the h2 adapter,
   because error handlers might generate headers that cannot be rewritten
   inside the normal stack. *)
(* TODO This can be optimized not to convert a header if it is already
   lowercase. Another option is to use memoization to reduce GC pressure. *)
let lowercase_headers inner_handler request =
  let%lwt response = inner_handler request in
  if fst (Dream.version request) <> 1 then
    Dream.all_headers response
    |> List.map (fun (name, value) -> String.lowercase_ascii name, value)
    |> Dream.set_all_headers response;
  Lwt.return response
