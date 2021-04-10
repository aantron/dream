# `h-sql`

<br>

Let's serve a list of comments with a comment form!

```ocaml
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
%     comments |> List.iter (fun (_id, comment) ->
        <p><%s comment %></p><% ); %>
      <%s! Dream.form_tag ~action:"/" request %>
        <input name="text">
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
      let%lwt comments = Dream.sql list_comments request in
      Dream.respond (render comments request));

    Dream.post "/" (fun request ->
      match%lwt Dream.form request with
      | `Ok ["text", text] ->
        let%lwt () = Dream.sql (add_comment text) request in
        let%lwt comments = Dream.sql list_comments request in
        Dream.respond (render comments request)
      | _ ->
        Dream.empty `Bad_Request);

  ]
  @@ Dream.not_found
```

<pre><code><b>$ dune exec --root . ./sql.exe</b></code></pre>

<br>

Try visiting [http://localhost:8080](http://localhost:8080) and leaving some
comments!

![Comments](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/sql.png)

<br>

Several things are going on in this example. It...

- sets up the boilerplate for two SQL queries, `list_comments` and
  `add_comment` with
  [Caqti](https://paurkedal.github.io/ocaml-caqti/caqti/Caqti_connect_sig/module-type-S/module-type-CONNECTION/index.html);
- defines a template, `render`, for our app's main page;
- sets up a
  [pool of SQL connections](https://aantron.github.io/dream/#val-sql_pool) to
  `db.sqlite`; and
- sets up two routes, one for displaying the comment list, and one for
  receiving new comments from our CSRF-safe form (example
  [**`d-form`**](../d-form#files)).

We also take the opportunity to try out
[`Dream.sql_sessions`](https://aantron.github.io/dream/#val-sql_sessions), which
stores session data persistently in `db.sqlite`! See example
[**`b-session`**](../b-session#files) for an introduction to session management.

<br>

`db.sqlite` was initialized with this schema, using the `sqlite3` command:

```sql
CREATE TABLE comment (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text NOT NULL);

CREATE TABLE dream_session (
  key TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  expires_at REAL NOT NULL,
  payload TEXT NOT NULL
);
```

We also had to make an addition to our Dune file:

<pre>(executable
 (name sql)
 (libraries <b>caqti-driver-sqlite3</b> dream)
 (preprocess (pps lwt_ppx)))

(rule
 (targets sql.ml)
 (deps sql.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
</pre>

<!-- TODO Recommend a redirect for better refresh behavior. -->

<br>

SQLite is good for small-to-medium sites and examples. For a larger site,
microservices, or other needs, you can switch, for example, to PostgreSQL by...

- running PostgreSQL, typically in a [Docker
  container](https://hub.docker.com/_/postgres/);
- changing the connection URI to `postgres://user:password@host:port`;
- using `caqti-driver-postgres`;
- replacing `INTEGER PRIMARY KEY AUTOINCREMENT` by `SERIAL PRIMARY KEY`.

A good program for examining the database locally is
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

- [**`i-graphql`**](../i-graphql#files) handles GraphQL queries and serves
  GraphiQL.
- [**`j-stream`**](../j-stream#files) streams response bodies to clients.

<br>

[Up to the tutorial index](../#readme)
