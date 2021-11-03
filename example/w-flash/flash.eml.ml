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
  Dream.initialize_log ~level:`Warning ();
  Dream.set_log_level "jst_log" `Info;
  Dream.set_log_level "dream.flash" `Info;
  let sublog = Dream.sub_log "jst_log" in
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
          let () = Dream.put_flash "Info" text request in
          sublog.info (fun log -> log ~request "%s" "Test log message.");
          Dream.set_log_level "jst_log" `Error;
          sublog.info (fun log -> log ~request "%s" "Shouldn't see this.");
          Dream.redirect request "/result"
        | _ ->
          Dream.redirect request "/");

    Dream.get "/result"
      (fun request ->
        Dream.html (result request));

  ]
  @@ Dream.not_found
