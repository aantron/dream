let add_header response buffered_body =

  let length =
    match buffered_body with
    | `Empty -> 0
    | `String body -> String.length body
    | `Bigstring body -> Dream_.Bigstring.size_in_bytes body
  in

  Lwt.return
    (Dream_.add_header "Content-Length" (string_of_int length) response)



let assign ?(buffer_streams = false) next_handler request =
  let open Lwt.Infix in

  next_handler request
  >>= fun response ->

  if Dream_.has_header "Content-Length" response then
    Lwt.return response

  else
    match !(response.body) with
    | #Dream_.buffered_body as buffered_body ->
      add_header response buffered_body

    | _ ->
      if not buffer_streams then
        Lwt.return response
      else
        Dream_.buffer_body response >>= add_header response
