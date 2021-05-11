(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO LATER Is there something with lighter dependencies? Although perhaps
   these are not so bad... *)

let initialize =
  lazy (Mirage_crypto_rng_lwt.initialize ())

let random_buffer n =
  Lazy.force initialize;
  Mirage_crypto_rng.generate n

let random n =
  Cstruct.to_string (random_buffer n)
