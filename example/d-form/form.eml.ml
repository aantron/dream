let show_form ?message request =
  <html>
  <body>

%   begin match message with
%   | None -> ()
%   | Some message ->
      <p>You entered: <b><%s message %>!</b></p>
%   end;

    <form method="POST" action="/">
      <%s! Dream.csrf_tag request %>
      <input name="message" autofocus>
    </form>

  </body>
  </html>

let () = Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (show_form request));

    Dream.post "/"
      (fun request ->
        match Dream.form request with
        | `Ok ["message", message] ->
          Dream.html (show_form ~message request)
        | _ ->
          Dream.empty `Bad_Request);

  ]
