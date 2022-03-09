let render response =
  let () =
    %% response
    <html>
    <body>

%     let rec paragraphs index =
        <p><%i index %></p>
%       Dream.flush response;
%       Eio_unix.sleep 1.;
%       if index < 10 then paragraphs (index + 1)
%     in
%     paragraphs 0;

    </body>
    </html>
  in
  Dream.close response

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ fun request -> Dream.stream ~headers:["Content-Type", Dream.text_html] request render
