FROM ocaml/opam:alpine as build

# Install system dependencies
# Some of these are only needed for database and JavaScript stuff, but this is 
# our build context, it won't impact our runtime environment.
RUN sudo apk add --update \
    make libffi-dev linux-headers m4 ncurses-dev perl pkgconf postgresql-dev \
    musl-dev git pkgconfig gmp-dev libc-dev openblas-dev zlib-dev \
    npm nodejs libev-dev

WORKDIR /build

# Install dependencies
# We only copy the opam file to install dependencies only when they change,
# and not every time a source file is modified.
ADD hello.opam hello.opam
RUN eval $(opam env) && opam install . --deps-only

# Build project
ADD . .

RUN opam exec -- dune build

FROM alpine:3.12 as run

RUN apk add --update gmp libpq libev

COPY --from=build /build/_build/default/app.exe /bin/app

CMD /bin/app
