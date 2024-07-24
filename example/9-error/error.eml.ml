let my_error_template _error debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status
  and reason = Dream.status_to_string status in

  Dream.set_header suggested_response "Content-Type" Dream.text_html;
  Dream.set_body suggested_response begin
    <html>
    <body>
      <h1><%i code %> <%s reason %></h1>
      <pre><%s debug_info %></pre>
    </body>
    </html>
  end;
  suggested_response

let () = Eio_main.run @@ fun env ->
  Dream.run ~error_handler:(Dream.error_template my_error_template) env
  @@ Dream.logger
  @@ fun _ -> Dream.empty `Not_Found
