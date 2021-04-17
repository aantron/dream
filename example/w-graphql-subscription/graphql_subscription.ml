let count until =
  let stream, push = Lwt_stream.create () in

  Lwt.async begin fun () ->
    let rec loop n =
      let%lwt () = Lwt_unix.sleep 0.5 in
      if n > until
      then (push None; Lwt.return_unit)
      else (push (Some n); loop (n + 1))
    in
    loop 1
  end;

  stream

let schema =
  let open Graphql_lwt.Schema in
  schema []
    ~subscriptions:[
      subscription_field "count"
        ~typ:(non_null (int))
        ~args:Arg.[arg "until" ~typ:(non_null int)]
        ~resolve:(fun _info until ->
          Lwt.return (Ok (count until, ignore)))
    ]

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referer_check
  @@ Dream.router [
    Dream.any "/graphql"  (Dream.graphql Lwt.return schema);
    Dream.get "/graphiql" (Dream.graphiql "/graphql");
  ]
  @@ Dream.not_found
