let my_error_template debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status
  and reason = Dream.status_to_string status in

  suggested_response
  |> Dream.with_body begin
    <html>
      <body>
        <h1><%i code %> <%s reason %></h1>
%       begin match debug_info with
%       | None -> ()
%       | Some debug_info ->
          <pre><%s debug_info %></pre>
%       end;
      </body>
    </html>
  end
  |> Lwt.return

let () =
  Dream.run ~error_handler:(Dream.error_template my_error_template)
  @@ Dream.logger
  @@ Dream.not_found
