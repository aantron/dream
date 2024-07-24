let count = ref 0

let count_requests inner_handler request =
  count := !count + 1;
  inner_handler request

let () = Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ count_requests
  @@ Dream.router [
    Dream.get "/" (fun _ ->
      Dream.html (Printf.sprintf "Saw %i request(s)!" !count));
  ]
