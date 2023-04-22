let render = response => {
  %% response
  <html>
  <body>

%     let rec paragraphs = index => {
        <p><%i index %></p>
%       Dream.flush(response);
%       Eio_unix.sleep(1.);
%       if (index < 10) paragraphs(index + 1);
%     };
%     paragraphs(0);

  </body>
  </html>
};

let () =
  Eio_main.run @@ env =>
  Dream.run(env)
  @@ Dream.logger
  @@ _ => Dream.stream(~headers=[("Content-Type", Dream.text_html)], render);
