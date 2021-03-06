(* TODO LATER Is there something with lighter dependencies? Althoguh perhaps
   these are not so bad... *)

let initialize =
  lazy (Mirage_crypto_rng_lwt.initialize ())

let random n =
  Lazy.force initialize;
  Cstruct.to_string (Mirage_crypto_rng.generate n)
