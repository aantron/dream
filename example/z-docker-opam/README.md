# `z-docker-opam`

<br>

This example runs a simple Web app inside a [Docker](https://www.docker.com/) container using [opam](https://opam.ocaml.org/) as the package manager.

Build the image from `Dockerfile`
```
DOCKER_BUILDKIT=1 docker build . --tag "docker-opam-im"
```

create and run the container
```
docker run --name docker-opam -p 8080:8080 docker-opam-im:latest
```

see also [**`z-docker-esy`**](../z-docker-esy#folders-and-files) for using `esy` package manager and `Docker compose`.

<br>

[Up to the example index](../#deploying)
