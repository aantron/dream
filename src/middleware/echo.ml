(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* TODO Convert to streaming later. *)
let echo request =
  Lwt.map Dream.response (Dream.body request)
