module Dream = Dream__pure.Inmost


let log =
  Log.sub_log "dream.flash_message"


type category = [
    | `Debug
    | `Info
    | `Warning
    | `Error
]

let key_of_category l =
  let suffix = match l with
    | `Debug -> "debug"
    | `Info -> "info"
    | `Warning -> "warning"
    | `Error -> "error" in
  "dream.flash_message." ^ suffix

let all_categories = [`Debug; `Info; `Warning; `Error]

let five_minutes = 5. *. 60.

let storage = Dream.new_local ~name:"dream.flash_message" ()


let flash_messages inner_handler request =
  let outbox = ref [] in
  let request = Dream.with_local storage outbox request in
  let%lwt response = inner_handler request in
  Lwt.return(
    List.fold_left (fun resp category ->
        let name = key_of_category category in
        let value = List.assoc_opt category !outbox in
        match value with
        | Some message ->
          Dream.set_cookie name message request resp ~max_age:five_minutes
        | None ->
          Dream.set_cookie name "" request resp ~expires:0.
      )
      response all_categories
  )


let get_flash category request =
  let k = key_of_category category in
  Dream.cookie k request


let put_flash category message request =
  let outbox = match Dream.local storage request with
  | Some outbox -> outbox
  | None ->
    let message = "Missing flash message middleware" in
    log.error (fun log -> log ~request "%s" message);
    failwith message in
  outbox := !outbox
  |> List.remove_assoc category
  |> fun dictionary -> (category, message) :: dictionary
