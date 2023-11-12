# `w-postgres`

<br>

This example shows how to use
[Docker](https://en.wikipedia.org/wiki/Docker_(software)) and
[Docker Compose](https://docs.docker.com/compose/) to manage a simple
Web server with a PostgreSQL database.

The
[code](https://github.com/aantron/dream/blob/master/example/w-postgres/postgres.eml.ml)
is almost identical to [**`h-sql`**](../h-sql#files). The only differences are:

- we now listen on `"0.0.0.0"`, since our client will definitely be outside the
  Docker container, so not on `localhost`, and
- we change the connection string from SQLite to PostgreSQL.

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.sql_pool "postgresql://dream:password@postgres/dream"
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

In addition, we now link with `caqti-driver-postgres` instead of
`caqti-driver-sqlite3` in
[`dune`](https://github.com/aantron/dream/blob/master/example/w-postgres/dune):

<pre><code>(executable
 (name postgres)
 <b>(libraries caqti-driver-postgresql dream)</b>
 (preprocess (pps lwt_ppx)))</code></pre>

and the
[schema](https://github.com/aantron/dream/blob/master/example/w-postgres/schema.sql) is slightly different, due to differences in PostgreSQL syntax, compared to
SQLite:

<pre><code>CREATE TABLE comment (
  <b>id SERIAL PRIMARY KEY,</b>
  text TEXT NOT NULL
);</code></pre>

To build, run:

<pre><code><b>$ cd example/w-postgres</b>
<b>$ docker-compose build</b>
<b>$ docker-compose up</b></code></pre>

This will build and start the
[two containers](https://github.com/aantron/dream/blob/master/example/w-postgres/docker-compose.yml),
one for PostgreSQL and one for our Web server. The first build of the Web server
will take several minutes. Later builds will be faster, due to caching.

On the first start, the database does not have a
[schema](https://github.com/aantron/dream/blob/master/example/w-postgres/schema.sql),
so open another terminal session and run

<pre><code><b>$ docker-compose exec postgres psql -U dream -c "$(cat schema.sql)"</b></code></pre>

Finally, visit [`http://localhost:8080`](http:/localhost:8080) and try out the
application!

<br>

Tips:

- If you modify
  [`postgres.eml.ml`](https://github.com/aantron/dream/blob/master/example/w-postgres/postgres.eml.ml),
  run

  ```
  docker-compose build && docker-compose up web
  ```

- To view the logs from the Web server container only, without having them mixed
  with the database logs, run

  ```
  docker-compose up -d
  docker-compose logs web -f
  ```

- The database container includes the
  [`psql`](https://tomcam.github.io/postgres/) command-line database client.
  You can access its REPL with

  ```
  docker-compose exec postgres psql -U dream
  ```

<br>

**See also:**

- [**`h-sql`**](../h-sql#files) is the SQLite, non-Docker version of this
  example.
- [**`z-docker-esy`**](../z-docker-esy#files) deploys to Digital Ocean with
  Docker Compose and esy, including Docker installation instructions.
- [**`z-docker-opam`**](../z-docker-opam#files) deploys with Docker Compose and
  opam.

<br>

[Up to the example index](../#examples)
