open Lwt.Infix

module Dream = Dream__pure.Inmost
module Error = Dream__middleware.Error

let to_dream_method method_ =
  Httpaf.Method.to_string method_ |> Dream.string_to_method

let to_httpaf_status status =
  Dream.status_to_int status |> Httpaf.Status.of_code

let to_h2_status status =
  Dream.status_to_int status |> H2.Status.of_code

let forward_body_general (response : Dream.response)
  (write_string : ?off:int -> ?len:int -> string -> unit)
  (write_bigstring : ?off:int -> ?len:int -> Dream.bigstring -> unit)
  http_flush close =
  let rec send () =
    response
    |> Dream.next
      ~bigstring
      ~string
      ~flush
      ~close
      ~exn:ignore
  and bigstring chunk off len =
    write_bigstring ~off ~len chunk;
    send ()
  and string chunk off len =
    write_string ~off ~len chunk;
    send ()
  and flush () =
    http_flush send
  in
  send ()

let forward_body
    (response : Dream.response)
    (body : [ `write ] Httpaf.Body.t) =
  forward_body_general
    response
    (Httpaf.Body.write_string body)
    (Httpaf.Body.write_bigstring body)
    (Httpaf.Body.flush body)
    (fun () -> Httpaf.Body.close_writer body)

let with_httpaf app _user's_error_handler user's_dream_handler =
  let request_handler (edn : string) (reqd : Httpaf.Reqd.t) =
    Dream__middleware.Log.set_up_exception_hook () ;
    let request = Httpaf.Reqd.request reqd in
    let client  = edn in
    let method_ = to_dream_method request.meth in
    let target  = request.target in
    let version = request.version.major, request.version.minor in
    let headers = Httpaf.Headers.to_list request.headers in
    let body    = Httpaf.Reqd.request_body reqd in
    let request : Dream.request = Dream.request_from_http ~app ~client ~method_ ~target ~version ~headers in
    Lwt.async begin fun () ->
      Dream.flush request >>= fun () ->
      let on_eof () = Dream.close_stream request |> ignore in
      let rec loop () =
        Httpaf.Body.schedule_read
          body
          ~on_eof
          ~on_read:(fun buffer ~off ~len ->
            Lwt.on_success
              (Dream__pure.Body.write_bigstring buffer off len request.body)
              loop) in
      loop () ; Lwt.return_unit end ;
    Lwt.async begin fun () ->
      Lwt.catch begin fun () ->
        user's_dream_handler request >>= fun response ->
        let forward_response response =
          let headers = Httpaf.Headers.of_list (Dream.all_headers response) in
          let status  = to_httpaf_status (Dream.status response) in
          let httpaf_response = Httpaf.Response.create ~headers status in
          let body    = Httpaf.Reqd.respond_with_streaming reqd httpaf_response in
          forward_body response body ;
          Lwt.return_unit in
        match Dream.is_websocket response with
        | None -> forward_response response
        | Some _user's_websocket_handler -> assert false (* TODO *)
      end @@ fun exn ->
        Httpaf.Reqd.report_exn reqd exn ;
        Lwt.return_unit
    end in
  request_handler

let forward_body_h2
    (response : Dream.response)
    (body : [ `write ] H2.Body.t) =
  forward_body_general
    response
    (H2.Body.write_string body)
    (H2.Body.write_bigstring body)
    (H2.Body.flush body)
    (fun () -> H2.Body.close_writer body)

let with_h2 app _user's_error_handler user's_dream_handler =
  let request_handler edn reqd =
    Dream__middleware.Log.set_up_exception_hook () ;
    let request = H2.Reqd.request reqd in
    let client  = edn in
    let method_ = to_dream_method request.meth in
    let target  = request.target in
    let version = (2, 0) in
    let headers = H2.Headers.to_list request.headers in
    let body    = H2.Reqd.request_body reqd in
    let request : Dream.request = Dream.request_from_http ~app ~client ~method_ ~target ~version ~headers in
    Lwt.async begin fun () ->
      Dream.flush request >>= fun () ->
      let on_eof () = Dream.close_stream request |> ignore in
      let rec loop () =
        H2.Body.schedule_read
          body
          ~on_eof
          ~on_read:(fun buffer ~off ~len ->
            Dream__pure.Body.write_bigstring buffer off len request.body
            |> ignore ;
            loop ()) in
      loop () ; Lwt.return_unit end ;
    Lwt.async begin fun () ->
      Lwt.catch begin fun () ->
        user's_dream_handler request >>= fun response ->
        let forward_response response =
          let headers = H2.Headers.of_list (Dream.all_headers response) in
          let status = to_h2_status (Dream.status response) in
          let h2_response = H2.Response.create ~headers status in
          let body = H2.Reqd.respond_with_streaming reqd h2_response in
          forward_body_h2 response body ;
          Lwt.return_unit in
        match Dream.is_websocket response with
        | None -> forward_response response
        | Some _user's_websocket_handler -> assert false (* TODO *)
      end @@ fun exn ->
        H2.Reqd.report_exn reqd exn ;
        Lwt.return_unit
    end in
  request_handler

let service (app, user's_dream_handler) info accept close =
  let request_handler edn : [ `write ] Alpn.reqd_handler -> unit = function
    | Alpn.Reqd_handler (HTTP_1_0, reqd) -> with_httpaf app () user's_dream_handler edn reqd
    | Alpn.Reqd_handler (HTTP_1_1, reqd) -> with_httpaf app () user's_dream_handler edn reqd
    | Alpn.Reqd_handler (HTTP_2_0, reqd) -> with_h2 app () user's_dream_handler edn reqd in
  let error_handler _edn ?request:_ _error _response = () (* TODO *) in
  Alpn.serve info ~error_handler ~request_handler accept close
