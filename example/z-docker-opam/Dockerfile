FROM ocaml/opam:alpine as build

# Install system dependencies
RUN sudo apk add --update libev-dev openssl-dev

WORKDIR /home/opam

# Install dependencies
ADD hello.opam hello.opam
RUN opam install . --deps-only

# Build project
ADD . .
RUN opam exec -- dune build



FROM alpine:3.12 as run

RUN apk add --update libev

COPY --from=build /home/opam/_build/default/app.exe /bin/app

ENTRYPOINT /bin/app
