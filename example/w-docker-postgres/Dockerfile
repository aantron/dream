FROM ocaml/opam:alpine as build

# Install system dependencies
RUN sudo apk add --update libev-dev openssl-dev libpq postgresql-dev

WORKDIR /home/opam

# Install dependencies
ADD app.opam app.opam
RUN opam install . --deps-only

# Build project
ADD . .
RUN opam exec -- dune build



FROM alpine:3.12 as run

RUN apk add --update libev libpq postgresql-dev

COPY --from=build /home/opam/_build/default/app.exe /bin/app

ENTRYPOINT /bin/app
