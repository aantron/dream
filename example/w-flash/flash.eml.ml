let form request =
  <html>
  <body>
    <%s! Dream.form_tag ~action:"/" request %>
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
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash_messages
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
        Dream.html (form request));

    Dream.post "/"
      (fun request ->
        match Dream.form request with
        | `Ok ["text", text] ->
          Dream.put_flash request "Info" text;
          Dream.redirect request "/result"
        | _ ->
          Dream.redirect request "/");

    Dream.get "/result"
      (fun request ->
        Dream.html (result request));

  ]
  @@ Dream.not_found
