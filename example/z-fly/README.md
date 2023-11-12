# `z-fly`

<br>

This example deploys a very simple Dream
[application](https://github.com/aantron/dream/blob/master/example/z-fly/app.ml)
to [Fly.io](https://www.fly.io/), a hosting platform that scales and smartly
moves your servers closer to your users. A low-usage app can be hosted for
[free](https://fly.io/docs/about/pricing/#free-tier). Fly.io offers
[`flyctl`](https://fly.io/docs/getting-started/installing-flyctl/), their CLI,
that makes [deployment](https://fly.io/docs/hands-on/start/) and
[scaling](https://fly.io/docs/reference/scaling/) very easy.

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Dream deployed on Fly.io!");
  ]
```

It uses [Docker Compose](https://docs.docker.com/compose/), so that you can
quickly expand it by adding databases and other services.

```yaml
version: "3"

services:
  web:
    build: .
    ports:
      - "8080:8080"
    restart: always
    logging:
      driver: ${LOGGING_DRIVER:-json-file}
```

The setup can be run locally or on any server provider.

The
[`Dockerfile`](https://github.com/aantron/dream/blob/master/example/z-docker-esy/Dockerfile)
has two stages: one for building our application, and one for the runtime that
only contains the final binary and its run-time dependencies.

<br>

## Deploying

Fly has a [setup guide](https://fly.io/docs/hands-on/start/) that we'll follow.

1. Install `flyctl` with `curl -L https://fly.io/install.sh | sh` or follow the
   specific [instructions](https://fly.io/docs/hands-on/installing/) for your
   system.
2. Run `fly launch` to initialize and deploy your project.

That should be it! Assuming no errors, the cli will print a link to your live
app.

<br>

## Development

For local development you can run your app with or without Docker. Setting up
the Docker build for the first time may take at least 4 minutes. Subsequent
builds are cached.

With Docker:

1. [Install Docker](https://www.docker.com/get-started).
2. Ensure Docker is running, then run `docker compose up`. Docker should build,
   cache, and serve your app at `localhost:8080`.

Without Docker:

1. Make sure you have [esy](https://esy.sh) installed.
2. Run `esy` to install all dependencies.
3. To start your app, run `esy start`. This is an aliased command set up inside
   `esy.json`.

<br>

[Up to the example index](../#deploying)
