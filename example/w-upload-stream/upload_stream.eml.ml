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
%   files |> List.iter begin fun (name, size) ->
%     let name =
%       match name with
%       | None -> "None"
%       | Some name -> name
%     in
      <p><%s name %>, <%i size %> bytes</p>
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
      let rec receive file_sizes =
        match Dream.upload request with
        | None -> Dream.html (report (List.rev file_sizes))
        | Some (_, filename, _) ->
          let rec count_size size =
            match Dream.upload_part request with
            | None -> receive ((filename, size)::file_sizes)
            | Some chunk -> count_size (size + String.length chunk)
          in
          count_size 0
      in
      receive []);

  ]
  @@ Dream.not_found
