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
%   files |> List.iter begin fun (name, content) ->
%     let name =
%       match name with
%       | None -> "None"
%       | Some name -> name
%     in
      <p><%s name %>, <%i String.length content %> bytes</p>
%   end;
  </body>
  </html>

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/" (fun request ->
      Dream.html (home request));

    Dream.post "/" (fun request ->
      match Dream.multipart request with
      | `Ok ["files", files] -> Dream.html (report files)
      | _ -> Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
