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
      Dream.html (home request));

    Dream.post "/" (fun request ->
      match%lwt Dream.multipart request with
      | `Ok parts ->
        let fold acc = function
          | "files", files ->
            let fold = fun acc -> function
              | { Dream.filename= Some filename; contents; _ } -> (filename, contents) :: acc
              | _ -> acc in
            List.fold_left fold acc files
          | _ -> acc in
        Dream.html (report (List.fold_left fold [] parts))
      | _ -> Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
