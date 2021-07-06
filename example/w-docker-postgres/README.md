# `w-docker-postgres`

<br>

This example illustrates how to use
[Docker](https://en.wikipedia.org/wiki/Docker_(software)) and
[docker-compose](https://docs.docker.com/compose/) to manage a simple
web server with a Postgres database.

Running a database under docker can simplify the process of setting up
a development environment. This is especially true if your application
uses several databases or services and you want a convenient way to
manage them all with a single tool.

The example app allows users to see a list of existing comments and
post new comments. Take a look at this
[example](https://github.com/aantron/dream/tree/master/example/h-sql#files)
for more background information.

## Getting Set Up

Start your docker containers by running `docker-compose up -d`. It
will take some time to build the `web` container; subsequent rebuilds
are faster.

When both containers are available, you should see:
```
Creating network "w-docker-postgres_default" with the default driver
Creating w-docker-postgres_postgres_1 ... done
Creating w-docker-postgres_web_1      ... done
```

At this point the PostgreSQL database is ready but doesn't have any
tables. Fix that by running:

```
docker-compose exec postgres psql -U dream -c "$(cat schema.sql)"
```

This will create the `comment` and `dream_session` tables described in
`schema.sql`.

Finally, open your browser to
[`http://localhost:8080/`](http://localhost:8080/) to try the
application.


## Tips

If you modify `app.eml.ml`, you will need to run
```
docker-compose build && docker-compose up web
```
to rebuild the `web` container and see your changes.

To view the logs from the API container (rather than having them mixed
in with the logs from the database) run:
```
docker-compose logs web -f
```

The database container contains a copy of the `psql` client. Running

```
docker-compose exec postgres psql -U dream
```

will allow you to start the client and run queries interactively.

<br>

**See also:**

- [**`h-sql`**](../h-sql#files) this example contains essentially the
  same application, but uses sqlite.
- [**`z-docker-esy`**](../z-docker-esy#files) describes how to deploy
  with docker-compose and esy.
- [**`z-docker-opam`**](../z-docker-opam#files) describes how to deploy
  with docker-compose and opam.

<br>

[Up to the example index](../#examples)
