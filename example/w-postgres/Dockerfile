FROM ocaml/opam:debian-12-ocaml-5.1 as build
WORKDIR /build

# Install dependencies.
RUN sudo apt-get update
RUN sudo apt-get install -y libev-dev libpq-dev pkg-config
ADD . .
RUN opam install --deps-only .

# Build project.
RUN opam exec -- dune build



FROM debian:stable-20231120-slim as run

RUN apt-get update
RUN apt-get install -y libev4 libpq5 libssl3

COPY --from=build /build/_build/default/postgres.exe /bin/postgres

ENTRYPOINT /bin/postgres
