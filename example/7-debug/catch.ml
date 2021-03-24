(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let () =
  Dream.run ~debug:true
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.respond "Good morning, world!");

    Dream.get "/bad"
      (fun _ ->
        Dream.respond ~status:`Forbidden "");

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The web app had a fail!"));

  ]
  @@ fun _ ->
    Dream.respond ~status:`Not_Found ""
