let input_form request =
  <html>
    <body>
      Enter some text:
      <%s! Dream.form_tag ~action:"/" request %>
        <input name="text" autofocus>
      </form>

    </body>
  </html>


let results_page info text =
  <html>
    <body>
      <p><%s Option.value info ~default:"" %></p>
      <p><%s Option.value text ~default:"" %></p>
    </body>
  </html>


let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/"
      (fun request ->
         Dream.html (input_form request));

    Dream.post "/"
      (fun request ->
        match%lwt Dream.form request with
        | `Ok ["text", text] ->
          let%lwt () = Dream.put_flash Info "Text received!" request in
          let%lwt () = Dream.put_session "text" text request in
          Dream.redirect request "/results"
        | _ ->
          Dream.redirect request "/"
      );

    Dream.get "/results"
      (fun request ->
         let%lwt info = Dream.get_flash Info request in
         let text = Dream.session "text" request in
         Dream.html (results_page info text));
  ]
  @@ Dream.not_found
