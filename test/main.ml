let app =
  Dream.start
  @@ Dream.request_id
  @@ Dream.log

  @@ fun _request ->
    ignore (raise Not_found);
    ignore (assert false);
    Lwt.return @@ Dream.response ~headers:["Content-Length", "0"] ()

let () =
  Dream.Httpaf.run app
