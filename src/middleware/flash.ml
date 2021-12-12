(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Joseph Thomas *)



module Dream = Dream_pure.Inmost



let log =
  Log.sub_log "dream.flash"

let five_minutes =
  5. *. 60.

let storage =
  Dream.new_local ~name:"dream.flash" ()

let flash_cookie =
  "dream.flash"

(* This is a soft limit. Encryption and base64 encoding increase the
   original size of the cookie text by ~4/3.*)
let content_byte_size_limit =
  3072

let (|>?) =
  Option.bind



let flash request =
  let rec group x =
    match x with
    | x1::x2::rest -> (x1, x2)::(group rest)
    | _ -> []
  in
  let unpack u =
    match u with
    | `String x -> x
    | _ -> failwith "Bad flash message content"
  in
  let x =
    Cookie.cookie flash_cookie request
    |>? fun value ->
    match Yojson.Basic.from_string value with
    | `List y -> Some (group @@ List.map unpack y)
    | _ -> None
  in
  Option.value x ~default:[]

let put_flash category message request =
  let outbox =
    match Dream.local storage request with
    | Some outbox -> outbox
    | None ->
      let message = "Missing flash message middleware" in
      log.error (fun log -> log ~request "%s" message);
      failwith message
  in
  outbox := (category, message)::!outbox



let flash_messages inner_handler request =
  log.debug (fun log ->
    let current =
      flash request
      |> List.map (fun (p,q) -> p ^ ": " ^ q)
      |> String.concat ", " in
    if String.length current > 0 then
      log ~request "Flash messages: %s" current
    else
      log ~request "%s" "No flash messages.");
  let outbox = ref [] in
  let request = Dream.with_local storage outbox request in
  let existing = Cookie.cookie flash_cookie request in
  let%lwt response = inner_handler request in
  let entries = List.rev !outbox in
  let response =
    match existing, entries with
    | None, [] -> response
    | Some _, [] ->
      Cookie.set_cookie flash_cookie "" request response ~expires:0.
    | _, _ ->
      let content =
        List.fold_right (fun (x,y) a -> `String x :: `String y :: a) entries []
      in
      let value = `List content |> Yojson.Basic.to_string in
      let () =
        if String.length value >= content_byte_size_limit then
          log.warning (fun log ->
            log ~request
              "Flash messages exceed soft size limit (%d bytes)"
              content_byte_size_limit)
        else
          ()
      in
      Cookie.set_cookie flash_cookie value request response ~max_age:five_minutes
  in
  Lwt.return response
