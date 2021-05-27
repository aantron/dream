let input_form request =
  <html>
    <body>
      Enter the password:
      <%s! Dream.form_tag ~action:"/" request %>
        <input name="message" autofocus>
      </form>

    </body>
  </html>


let results_page request =
  <html>
    <body>
%     begin match Dream.get_messages request with
%     | (Dream.Info, message) :: _ ->
        <p><%s message %></p>
        <p>Here is the secret: 42.</p>
%     | (Dream.Error, message) :: _ ->
        <p>Error: <%s message%></p>
        <p>No secrets without the right password!</p>
%     | _ ->
        <p>No secrets for you!</p>
%     end;
    </body>
  </html>


let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.flash_messages
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
         Dream.html (input_form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["message", "password"] ->
          let%lwt () = Dream.add_message Info "Correct!" request in
          Dream.redirect request "/results"
        | `Ok ["message", _] ->
          let%lwt () = Dream.add_message Error "Wrong password!" request in
          Dream.redirect request "/results"
        | _ ->
          let%lwt () = Dream.add_message Error "Something went wrong!" request in
          Dream.redirect request "/"
      );

    Dream.get "/results"
      (fun request ->
         Dream.html (results_page request));
  ]
  @@ Dream.not_found
