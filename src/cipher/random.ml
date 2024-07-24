(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let random_buffer n =
  Mirage_crypto_rng.generate n

let random n =
  Cstruct.to_string (random_buffer n)
