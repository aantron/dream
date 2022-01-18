let count until =
  let stream, push = Lwt_stream.create () in
  let close () = push None in

  Lwt.async begin fun () ->
    let rec loop n =
      let%lwt () = Lwt_unix.sleep 0.5 in
      if n > until
      then (close (); Lwt.return_unit)
      else (push (Some n); loop (n + 1))
    in
    loop 1
  end;

  stream, close

let schema =
  let open Graphql_lwt.Schema in
  schema []
    ~subscriptions:[
      subscription_field "count"
        ~typ:(non_null int)
        ~args:Arg.[arg "until" ~typ:(non_null int)]
        ~resolve:(fun _info until ->
          Lwt.return (Ok (count until)))
    ]

let default_query =
  "subscription {\\n  count(until: 3)\\n}\\n"

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.origin_referrer_check
  @@ Dream.router [
    Dream.any "/graphql" (Dream.graphql Lwt.return schema);
    Dream.get "/" (Dream.graphiql ~default_query "/graphql");
  ]
  @@ Dream.not_found
