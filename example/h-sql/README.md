# `h-sql`

<br>

Let's serve a list of comments with a comment form! First, we define a couple ofhttps://paurkedal.github.io/ocaml-caqti/index.html/caqti-lwt/Caqti_lwt/module-type-CONNECTION/index.html
prepared statements using
[Caqti](https://paurkedal.github.io/ocaml-caqti/index.html/caqti-lwt/Caqti_lwt/module-type-CONNECTION/index.html),
a library for talking to SQL databases:

```ocaml
module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type

let list_comments =
  let query =
    let open Caqti_request.Infix in
    (T.unit ->* T.(t2 int string))
    "SELECT id, text FROM comment" in
  fun (module Db : DB) ->
    let%lwt comments_or_error = Db.collect_list query () in
    Caqti_lwt.or_fail comments_or_error

let add_comment =
  let query =
    let open Caqti_request.Infix in
    (T.string ->. T.unit)
    "INSERT INTO comment (text) VALUES ($1)" in
  fun text (module Db : DB) ->
    let%lwt unit_or_error = Db.exec query text in
    Caqti_lwt.or_fail unit_or_error

let render comments request =
  <html>
  <body>

%   comments |> List.iter (fun (_id, comment) ->
      <p><%s comment %></p><% ); %>

    <form method="POST" action="/">
      <%s! Dream.csrf_tag request %>
      <input name="text" autofocus>
    </form>

  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:db.sqlite"
  @@ Dream.sql_sessions
  @@ Dream.router [

    Dream.get "/" (fun request ->
      let%lwt comments = Dream.sql request list_comments in
      Dream.html (render comments request));

    Dream.post "/" (fun request ->
      match%lwt Dream.form request with
      | `Ok ["text", text] ->
        let%lwt () = Dream.sql request (add_comment text) in
        Dream.redirect request "/"
      | _ ->
        Dream.empty `Bad_Request);

  ]
```

<pre><code><b>$ cd example/h-sql</b>
<b>$ opam install --deps-only --yes .</b>
<b>$ dune exec --root . ./sql.exe</b></code></pre>

<br>

Try visiting [http://localhost:8080](http://localhost:8080) and leaving some
comments!

![Comments](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/sql.png)

<br>

We take the opportunity to try out
[`Dream.sql_sessions`](https://aantron.github.io/dream/#val-sql_sessions), which
stores session data persistently in `db.sqlite`. See example
[**`b-session`**](../b-session#folders-and-files) for an introduction to session management.
Both the comments and the sessions survive server restarts.

<br>

`db.sqlite` was initialized with this schema, using the `sqlite3` command:

```sql
CREATE TABLE comment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL
);

CREATE TABLE dream_session (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  expires_at REAL NOT NULL,
  payload TEXT NOT NULL
);
```

We also had to make an addition to our
[`dune`](https://github.com/aantron/dream/blob/master/example/h-sql/dune) file:

<pre>(executable
 (name sql)
 (libraries <b>caqti-driver-sqlite3</b> dream)
 (preprocess (pps lwt_ppx)))

(rule
 (targets sql.ml)
 (deps sql.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
</pre>

...and to
[`sql.opam`](https://github.com/aantron/dream/blob/master/example/h-sql/esy.json):

<pre>depends: [
  <b>"caqti-driver-sqlite3" {>= "1.7.0"}</b>
  "ocaml" {>= "4.08.0"}
  "dream"
  "dune" {>= "2.0.0"}
]
</pre>

<br>

SQLite is good for small-to-medium sites and examples. For a larger site,
microservices, or other needs, you can switch, for example, to PostgreSQL. See
[**`w-postgres`**](../w-postgres#folders-and-files).

A good program for examining databases locally is
[Beekeeper Studio](https://www.beekeeperstudio.io/). Dream might also integrate
an optional hosted database UI in the future, and you could choose to serve it
at some route.

<br>

See

- [`Caqti_connect_sig.S.CONNECTION`](https://paurkedal.github.io/ocaml-caqti/caqti/Caqti_connect_sig/module-type-S/module-type-CONNECTION/index.html)
  for Caqti's statement runners. These are the fields of the module `Db` in the
  example.
- [`Caqti_request`](https://paurkedal.github.io/ocaml-caqti/caqti/Caqti_request/)
  sets up prepared statements.
- [`Caqti_type`](https://paurkedal.github.io/ocaml-caqti/caqti/Caqti_type/) is
  used to specify the types of statement arguments and results.

<br>
<br>

**Next steps:**

- [**`i-graphql`**](../i-graphql#folders-and-files) handles GraphQL queries and serves
  GraphiQL.
- [**`j-stream`**](../j-stream#folders-and-files) streams response bodies to clients.

<br>

[Up to the tutorial index](../#readme)
