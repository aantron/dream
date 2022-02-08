let form request =
  <html>
  <body>
    <form action="/" method="post"><%s! Dream.csrf_tag request %>
      <input name="text" autofocus>
    </form>
  </body>
  </html>

let result request =
  <html>
  <body>

%   Dream.flash request |> List.iter (fun (category, text) ->
      <p><%s category %>: <%s text %></p><% ); %>

  </body>
  </html>

let () =
  Dream.set_log_level "dream.flash" `Debug;
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash_messages
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["text", text] ->
          let () = Dream.put_flash request "Info" text in
          Dream.redirect request "/result"
        | _ ->
          Dream.redirect request "/");

    Dream.get "/result"
      (fun request ->
        Dream.html (result request));

  ]
  @@ Dream.not_found
