# `w-stream-upload`

<br>

This example shows an upload form at
[http://localhost:8080](http://localhost:8080), which allows sending one big
file. When it is sent, the example saving the given file into the disk with the
new filename specified in `as`. It saving the given file _payload per payload_
to limit the memory consumption required by the server on such operation - in
other words, it streams out the incoming file. Finally, it show the new
filename and the size of it.

```ocaml
let home request =
  <html>
    <body>
      <%s! Dream.form_tag ~action:"/" ~enctype:`Multipart_form_data request %>
        <input name="as">
        <input name="file" type="file">
        <button>Submit!</button>
      </form>
    </body>
  </html>

let report where size =
  <html>
    <body>
        <p><%s where %>, <%Li size %> bytes</p>
    </body>
  </html>

let report files =
  <html>
    <body>
%     files |> List.iter begin fun (name, content) ->
        <p><%s name %>: <%i String.length content %> bytes</p>
%     end;
    </body>
  </html>

let write fd str size =
  let rec go fd str off max size =
    let%lwt len = Lwt_unix.write_string fd str off max in
    if len = max
    then Lwt.return (Int64.add size (Int64.of_int (String.length str)))
    else go fd str (off + len) (max - len) size in
  go fd str 0 (String.length str) size

let () =
  Dream.initialize_log
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [

    Dream.get  "/" (fun request ->
      Dream.html (home request));

    Dream.post "/" (fun request ->
      let rec iter_parts dst size = match%lwt Dream.upload request with
        | `Field _ -> iter_parts dst size
        | `Part (Some "as", _) ->
          let stream = Lwt_stream.from (fun () -> Dream.upload_part request) in
          let%lwt value = Lwt_stream.to_list stream in
          let value = String.concat "" value in
          iter_parts (Some value) size
        | `Part (Some "file", Some _) when dst <> None ->
          let filename = Option.get dst in
          let stream = Lwt_stream.from (fun () -> Dream.upload_part request) in
          let%lwt fd = Lwt_unix.openfile filename
	    Unix.[ O_WRONLY; O_CREAT; O_TRUNC ] 0o644 in
          let%lwt ln = Lwt_stream.fold_s (write fd) stream 0L in
          let%lwt () = Lwt_unix.close fd in
          iter_parts dst (Some ln)
        | `Part _ ->
          Dream.log "Serialize a part." ;
          let stream = Lwt_stream.from (fun () -> Dream.upload_part request) in
          let%lwt _ = Lwt_stream.to_list stream in
          iter_parts dst size
        | `Wrong_content_type as err -> Lwt.return_error err
        | `Done -> Lwt.return_ok (dst, size) in
      match%lwt iter_parts None None with
      | Ok (Some filename, Some size) ->
        Dream.html (report filename size)
      | _ -> Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The page shown after uploading looks like this:

```
foo.png, 104857600 bytes
```

<br>

This example uses
[`Dream.upload`](https://aantron.github.io/dream/#val-upload) and
[`Dream.upload_part](https://aantron.github.io/dream/#val-upload-part).
A sequential call to these functions should look likes:
```ocaml
# Dream.upload request ;;
- : [> `Field of (string * string) ] = `Field ("content-type", ...)
# Dream.upload request ;;
- : [> `Field of (string * string) ] = `Field ("content-disposition", ...)
# Dream.upload request ;;
- : [> `Part of (string option * string option) ] =
  `Part (Some "file", Some "foo.png")
# Dream.upload_part request ;;
- : string option = Some "..."
# Dream.upload_part request ;;
- : string option = Some "..."
# Dream.upload_part request ;;
- : string option = None ;;
# Dream.upload request ;;
- : [> `Field of (string * string) ] = `Field ("content-type", ...)
# Dream.upload request ;;
- : [> `Part of (string option * string option) ] =
  `Part (Some "as", None)
# Dream.upload_part request ;;
- : string option = Some "..."
# Dream.upload_part request ;;
- : string option = None
# Dream.upload request ;;
- : [> `Done ] = `Done
```

By this way, it's possible to safely (from the memory consumption point of
view) to upload a large file.

<br>

## Security

[`Dream.upload`](https://aantron.github.io/dream/#val-upload) does not offer
built-in CSRF protection at all at present. You can, however, still use
[`Dream.form_tag`](https://aantron.github.io/dream/#val-form_tag), and manually
call
[`Dream.verify_csrf_token`](https://aantron.github.io/dream/#val-verify_csrf_token)
when you stream a `dream.csrf` field. You'll then have to decide what to do
about parts already received.

<br>
<br>

**Next steps:**

- [**`h-sql`**](../h-sql#files) runs SQL queries against a database.
- [**`i-graphql`**](../i-graphql#files) handles GraphQL queries and serves
  GraphiQL.

<br>

[Up to the tutorial index](../#readme)
