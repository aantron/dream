let counter = ref 0

let () =
  Dream.run
  @@ Dream.logger
  @@ (fun _ ->
    counter := !counter + 1;
    Dream.log "The count is now %i" !counter;
    Dream.respond (Printf.sprintf "You are visitor number %i!" !counter))
