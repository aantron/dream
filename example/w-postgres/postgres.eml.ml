module type DB = Caqti_lwt.CONNECTION
module R = Caqti_request
module T = Caqti_type

let list_comments =
  let query =
    R.collect T.unit T.(tup2 int string)
      "SELECT id, text FROM comment" in
  fun (module Db : DB) ->
    let%lwt comments_or_error = Db.collect_list query () in
    Caqti_lwt.or_fail comments_or_error

let add_comment =
  let query =
    R.exec T.string
      "INSERT INTO comment (text) VALUES ($1)" in
  fun text (module Db : DB) ->
    let%lwt unit_or_error = Db.exec query text in
    Caqti_lwt.or_fail unit_or_error

let render comments request =
  <html>
  <body>

%   comments |> List.iter (fun (_id, comment) ->
      <p><%s comment %></p><% ); %>

    <%s! Dream.form_tag ~action:"/" request %>
      <input name="text" autofocus>
    </form>

  </body>
  </html>

let () =
  Eio_main.run @@ fun env ->
  Dream.run ~interface:"0.0.0.0" env
  @@ Dream.logger
  @@ Dream.sql_pool "postgresql://dream:password@postgres/dream"
  @@ Dream.sql_sessions
  @@ Dream.router [

    Dream.get "/" (fun request ->
      let comments = Dream.sql request list_comments in
      Dream.html (render comments request));

    Dream.post "/" (fun request ->
      match Dream.form request with
      | `Ok ["text", text] ->
        Dream.sql request (add_comment text);
        Dream.redirect request "/"
      | _ ->
        Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
