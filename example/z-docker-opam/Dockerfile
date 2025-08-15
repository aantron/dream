# Build Stage
# # # # #

FROM ocaml/opam:alpine AS build

# Install system dependencies
RUN sudo apk add --update libev-dev openssl-dev gmp-dev

WORKDIR /home/opam

# Install dependencies
COPY z-docker-opam.opam z-docker-opam.opam
RUN opam install . --deps-only

# Build project
COPY . .
RUN opam exec -- dune build


# Run Stage
# # # # #

FROM alpine:3.18.4 AS run

RUN apk add --update libev

COPY --from=build /home/opam/_build/default/app.exe /bin/app

ENTRYPOINT [ "/bin/sh", "-c", "/bin/app" ]
