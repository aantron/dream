let render response =
  let%lwt () =
    %% response
    <html>
      <body>
%       let rec paragraphs index =
          <p><%i index %></p>
%         let%lwt () = Dream.flush response in
%         let%lwt () = Lwt_unix.sleep 1. in
%         paragraphs (index + 1)
%       in
%       let%lwt () = paragraphs 0 in
      </body>
    </html>
  in
  Dream.close_stream response

let () =
  Dream.run
  @@ Dream.logger
  @@ fun _ ->
    let response = Dream.response "" |> Dream.with_stream in
    Lwt.async (fun () -> render response);
    Lwt.return response
