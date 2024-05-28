# `z-docker-opam`

<br>

This example runs a simple Web app inside a [Docker](https://www.docker.com/)
container. It is a variant of [**`z-docker-esy`**](../z-docker-esy#files), but
with [opam](https://opam.ocaml.org/) as the package manager.

All the instructions are the same as in
[**`z-docker-esy`**](../z-docker-esy#files). The difference is in the
[`Dockerfile`](https://github.com/aantron/dream/blob/master/example/z-docker-opam/Dockerfile),
which, in this example, derives an image from one of the [opam base
images](https://hub.docker.com/r/ocaml/opam), and installs dependencies using
opam. The initial build requires at least 2 GB of memory.

<br>

[Up to the example index](../#deploying)
