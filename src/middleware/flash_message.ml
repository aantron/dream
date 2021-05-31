module Dream = Dream__pure.Inmost


let log =
  Log.sub_log "dream.flash_message"


let message_cookie = "dream.flash_message"


type level = Debug | Info | Success | Warning | Error


let key_of_level l =
  let suffix = match l with
    | Debug -> "debug"
    | Info -> "info"
    | Success -> "success"
    | Warning -> "warning"
    | Error -> "error" in
  message_cookie ^ "." ^ suffix


let all_levels = [Debug; Info; Success; Warning; Error]


let five_minutes = 5. *. 60.


let getter_ local request =
  match Dream.local local request with
  | Some outbox -> outbox
  | None ->
    let message = "Missing flash message middleware" in
    log.error (fun log -> log ~request "%s" message);
    failwith message


let middleware_ local max_age = fun inner_handler request ->
  let outbox = ref [] in
  let request = Dream.with_local local outbox request in
  let%lwt response = inner_handler request in
  Lwt.return(
    List.fold_left (fun resp level ->
        let name = key_of_level level in
        let value = List.assoc_opt level !outbox in
        match value with
        | Some message ->
          Dream.set_cookie name message request resp ~max_age
        | None ->
          Dream.set_cookie name "" request resp ~expires:0.
      )
      response all_levels
  )


type 'a typed_middleware = {
  middleware : float -> Dream.middleware;
  getter : Dream.request -> 'a;
}


let typed_middleware () =
  let local = Dream.new_local ~name:"dream.flash_message" () in
  {
    middleware = middleware_ local;
    getter = getter_ local;
  }


let {middleware; getter} = typed_middleware ()


let flash_messages ?(lifetime = five_minutes) = middleware lifetime


let get_flash level request =
  let k = key_of_level level in
  Dream.cookie k request


let put_flash level message request =
  let outbox = getter request in
  outbox := !outbox
  |> List.remove_assoc level
  |> fun dictionary -> (level, message) :: dictionary


let clear_flash level request =
  let outbox = getter request in
  outbox := !outbox
  |> List.remove_assoc level
