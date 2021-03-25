let count = ref 0

let count_requests inner_handler request =
  count := !count + 1;
  inner_handler request

let () =
  Dream.run
  @@ Dream.logger
  @@ count_requests
  @@ Dream.router [
    Dream.get "/dashboard" (fun _ ->
      Dream.respond (Printf.sprintf "Saw %i request(s)!" !count))
  ]
  @@ Dream.not_found
