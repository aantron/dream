let home request =
  <html>
    <body>
      <%s! Dream.form_tag ~action:"/" ~enctype:`Multipart_form_data request %>
        <input name="files" type="file" multiple>
        <button>Submit!</button>
      </form>
    </body>
  </html>

let report files =
  <html>
    <body>
%     files |> List.iter begin fun (name, content) ->
        <p><%s name %>, <%i String.length content %> bytes</p>
%     end;
    </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/" (fun request ->
      Dream.respond (home request));

    Dream.post "/" (fun request ->
      match%lwt Dream.multipart request with
      | `Ok ["files", `Files files] -> Dream.respond (report files)
      | _ -> Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
