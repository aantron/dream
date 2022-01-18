let successful = ref 0
let failed = ref 0

let count_requests inner_handler request =
  try
    let response = inner_handler request in
    successful := !successful + 1;
    response
  with exn ->
    failed := !failed + 1;
    raise exn

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ count_requests
  @@ Dream.router [

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The Web app failed!"));

    Dream.get "/" (fun _ ->
      Dream.html (Printf.sprintf
        "%3i request(s) successful<br>%3i request(s) failed"
        !successful !failed));

  ]
  @@ Dream.not_found
