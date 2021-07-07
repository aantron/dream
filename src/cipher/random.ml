(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO LATER Is there something with lighter dependencies? Although perhaps
   these are not so bad... *)

exception Entropy_is_not_initialized

let setup_entropy =
  "\nTo initialize entropy with a default random number generator, and \
   set up Dream, do the following:\
   \n  If you are using Lwt/Unix, execute `Dream.random_initialize ()`
   \n  If you are using MirageOS, use the Dream device in config.ml
   \n"

let () = Printexc.register_printer @@ function
  | Entropy_is_not_initialized ->
    Some ("The entropy is not yet initialized. " ^ setup_entropy)
  | _ -> None

let set = ref false

let _initialized = ref None

let initialized () : [ `Initialized ] =
  match !_initialized with
  | None -> raise Entropy_is_not_initialized
  | Some v -> Lazy.force v

let initialize f =
  if !set then Logs.debug (fun log -> log
    "Dream__cipher.Random.initialize has already been called, ignoring this call.")
  else begin
    ( try
        let `Initialized = initialized () in
        Format.eprintf
          "Dream__cipher.Random.initialize has already been set, check that this call \
          is intentional";
        with
          Entropy_is_not_initialized -> ());
    set := true ;
    _initialized := Some (Lazy.from_fun f)
  end

let random_buffer n =
  let `Initialized = initialized () in
  Mirage_crypto_rng.generate n

let random n =
  Cstruct.to_string (random_buffer n)
