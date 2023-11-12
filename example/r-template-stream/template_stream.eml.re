let render = response => {
  %% response
  <html>
  <body>

%   let rec paragraphs = index => {
      <p><%i index %></p>
%     let%lwt () = Dream.flush(response);
%     let%lwt () = Lwt_unix.sleep(1.);
%     paragraphs(index + 1);
%   };
%   let%lwt () = paragraphs(0);

  </body>
  </html>
};

let () =
  Dream.run
  @@ Dream.logger
  @@ _ => Dream.stream(~headers=[("Content-Type", Dream.text_html)], render);
