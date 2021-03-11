(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost

(* TODO This scheme is fragile to URL-encoding. So does that mean that the URL
   decoder will have to be built in, and run before the prefix middleware? *)
(* TODO This thing can respond with 502 - definitely at least document it. It
   may be better for it to even be passed to ~error_handler. *)
let site_root_prefix_check prefix =
  let prefix =
    Dream_pure.Formats.parse_target prefix
    |> fst
    |> Dream_pure.Formats.trim_empty_trailing_component
  in

  match prefix with
  | [] ->
    Dream.identity

  | prefix ->
    fun next_handler request ->
      (* We currently use an internal representation in which the "first"
         request already contains the site prefix. This is probably
         questionable. However, given that, we don't need to update the prefix
         in the request. We just need to check the target. If it is under the
         prefix, we chop the prefix and continue. If not, we fail with 502 Bad
         Gateway. *)

      let rec scan prefix path =

        match prefix, path with
        | prefix_crumb::prefix, path_crumb::path ->
          if path_crumb = prefix_crumb then
            scan prefix path
          else
            None

        | [], path ->
          Some path
        | _ ->
          None
      in

      match scan prefix (Dream.internal_path request) with
      | None ->
        Dream.respond ~status:`Bad_gateway ""

      | Some path ->
        request
        |> Dream.with_prefix prefix
        |> Dream.with_path path
        |> next_handler
