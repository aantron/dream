let render = clock => response => {
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

# let render = clock => response => {
#   let () = {
#     %% response
#     <html>
#     <body>

# %     let rec paragraphs = index => {
#         <p><%i index %></p>
# %       Dream.flush(response);
# %       Eio.Time.sleep(clock, 1.);
# %       if (index < 10) paragraphs(index + 1);
# %     };
# %     paragraphs(0);

  </body>
  </html>
};

let () =
  Eio_main.run @@ env =>
  Dream.run(env)
  @@ Dream.logger
  @@ request => Dream.stream(~headers=[("Content-Type", Dream.text_html)], request, render(env#clock));
