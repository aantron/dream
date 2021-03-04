let app =
  Dream.start
  @@ Dream.request_id
  @@ Dream.log

  @@ fun request ->
    let open Lwt.Infix in
    Dream.body request
    >>= fun body ->
    Dream.info (fun m -> m "body: \'%s\'" body);
    let response = Dream.response ~headers:["Content-Length", "6"] () in
    Lwt.return @@ Dream.set_body response "VERY KEWL"

let () =
  Dream.Httpaf.run app

(* TODO Need Content-Length middleware. *)
