let to_json request =
  match Dream.header "Content-Type" request with
  | Some "application/json" ->
    let%lwt body = Dream.body request in
    begin match Yojson.Basic.from_string body with
    | exception _ -> Lwt.return None
    | json -> Lwt.return (Some json)
    end
  | _ -> Lwt.return None

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referer_check
  @@ Dream.router [

    Dream.post "/"
      (fun request ->
        match%lwt to_json request with
        | None -> Dream.empty `Bad_Request
        | Some json ->

          let maybe_message =
            Yojson.Basic.Util.(member "message" json |> to_string_option) in
          match maybe_message with
          | None -> Dream.empty `Bad_Request
          | Some message ->

            `String message
            |> Yojson.Basic.to_string
            |> Dream.json);

  ]
  @@ Dream.not_found
