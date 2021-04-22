let home request =
  <html>
    <body>
      <%s! Dream.form_tag ~action:"/" ~enctype:`Multipart_form_data request %>
        <input name="as">
        <input name="file" type="file">
        <button>Submit!</button>
      </form>
    </body>
  </html>

let report where size =
  <html>
    <body>
        <p><%s where %>, <%Li size %> bytes</p>
    </body>
  </html>

let write fd str size =
  let rec go fd str off max size =
    let%lwt len = Lwt_unix.write_string fd str off max in
    if len = max
    then Lwt.return (Int64.add size (Int64.of_int (String.length str)))
    else go fd str (off + len) (max - len) size in
  go fd str 0 (String.length str) size

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/" (fun request ->
      Dream.html (home request));

    Dream.post "/" (fun request ->
      let rec iter_parts dst size = match%lwt Dream.upload request with
        | `Field _ -> iter_parts dst size
        | `Part (Some "as", _) ->
          let stream = Lwt_stream.from (fun () -> Dream.upload_part request) in
          let%lwt value = Lwt_stream.to_list stream in
          let value = String.concat "" value in
          iter_parts (Some value) size
        | `Part (Some "file", Some _) when dst <> None ->
          let filename = Option.get dst in
          let stream = Lwt_stream.from (fun () -> Dream.upload_part request) in
          let%lwt fd = Lwt_unix.openfile filename
            Unix.[ O_WRONLY; O_CREAT; O_TRUNC ] 0o644 in
          let%lwt ln = Lwt_stream.fold_s (write fd) stream 0L in
          let%lwt () = Lwt_unix.close fd in
          iter_parts dst (Some ln)
        | `Part _ ->
          Dream.log "Serialize a part." ;
          let stream = Lwt_stream.from (fun () -> Dream.upload_part request) in
          let%lwt _ = Lwt_stream.to_list stream in
          iter_parts dst size
        | `Wrong_content_type as err -> Lwt.return_error err
        | `Done -> Lwt.return_ok (dst, size) in
      match%lwt iter_parts None None with
      | Ok (Some filename, Some size) ->
        Dream.html (report filename size)
      | _ -> Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
