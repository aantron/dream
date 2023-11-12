let render response =
  %% response
  <html>
  <body>

%   let rec paragraphs index =
      <p><%i index %></p>
%     let%lwt () = Dream.flush response in
%     let%lwt () = Lwt_unix.sleep 1. in
%     paragraphs (index + 1)
%   in
%   let%lwt () = paragraphs 0 in

  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ fun _ -> Dream.stream ~headers:["Content-Type", Dream.text_html] render
