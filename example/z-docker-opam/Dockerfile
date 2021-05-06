FROM ocaml/opam:alpine as build

# Install system dependencies
RUN sudo apk add --update libev-dev openssl-dev

WORKDIR /build

# Install dependencies
ADD hello.opam hello.opam
RUN eval $(opam env) && opam install . --deps-only

# Build project
ADD . .
RUN opam exec -- dune build

FROM alpine:3.12 as run

RUN apk add --update libev

COPY --from=build /build/_build/default/app.exe /bin/app

CMD /bin/app
