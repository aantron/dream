let render = response => {
  let%lwt () = {
    %% response
    <html>
      <body>
%       let rec paragraphs = index => {
          <p><%i index %></p>
%         let%lwt () = Dream.flush(response);
%         let%lwt () = Lwt_unix.sleep(1.);
%         paragraphs(index + 1);
%       };
%       let%lwt () = paragraphs(0);
      </body>
    </html>
  };
  Dream.close_stream(response)
};

let () =
  Dream.run
  @@ Dream.logger
  @@ _ => {
    let response = Dream.response("") |> Dream.with_stream;
    Lwt.async(() => render(response));
    Lwt.return(response);
  };
