type message_object = {
  message : string;
} [@@deriving yojson]

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referrer_check
  @@ Dream.router [

    Dream.post "/"
      (fun request ->
        let%lwt body = Dream.body request in

        let message_object =
          body
          |> Yojson.Safe.from_string
          |> message_object_of_yojson
        in

        `String message_object.message
        |> Yojson.Safe.to_string
        |> Dream.json);

  ]
