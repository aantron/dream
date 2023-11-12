let form request =
  <html>
  <body>
    <form method="POST" action="/">
      <%s! Dream.csrf_tag request %>
      <input name="text" autofocus>
    </form>
  </body>
  </html>

let result request =
  <html>
  <body>

%   Dream.flash_messages request |> List.iter (fun (category, text) ->
      <p><%s category %>: <%s text %></p><% ); %>

  </body>
  </html>

let () =
  Dream.set_log_level "dream.flash" `Debug;
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["text", text] ->
          let () = Dream.add_flash_message request "Info" text in
          Dream.redirect request "/result"
        | _ ->
          Dream.redirect request "/");

    Dream.get "/result"
      (fun request ->
        Dream.html (result request));

  ]
