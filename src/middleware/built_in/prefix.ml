(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream_pure.Inmost

(* TODO This scheme is fragile to URL-encoding. So does that mean that the URL
   decoder will have to be built in, and run before the prefix middleware? *)
(* TODO This thing can respond with 502 - definitely at least document it. It
   may be better for it to even be passed to ~error_handler. *)
let site_root_prefix_check prefix =
  if prefix = "" then
    Dream.identity

  else
    fun next_handler request ->
      (* We currently use an internal representation in which the "first"
         request already contains the site prefix. This is probably
         questionable. However, given that, we don't need to update the prefix
         in the request. We just need to check the target. If it is under the
         prefix, we chop the prefix and continue. If not, we fail with 502 Bad
         Gateway. *)

      let prefix = Dream.prefix request
      and target = Dream.target request
      in

      let is_ok, request =
        if String.length target <= String.length prefix then
          false, request

        else
          let rec scan index =
            if index = String.length prefix then
              if target.[index] = '/' then
                true,
                Dream.with_target
                  (String.sub target index (String.length target - index))
                  request
              else
                false,
                request

            else
              if target.[index] = prefix.[index] then
                scan (index + 1)
              else
                false,
                request
          in
          scan 0
      in

      if is_ok then
        next_handler request
      else
        Dream.respond ~status:`Bad_gateway ""
