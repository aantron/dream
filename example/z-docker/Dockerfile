FROM ocaml/opam:alpine as build

# Install Esy-specific dependencies
RUN sudo apk add --update nodejs npm perl-utils m4 linux-headers

WORKDIR /build

RUN npm install esy

# Install dependencies
ADD esy.json esy.json
ADD esy.lock esy.lock
RUN node_modules/.bin/esy fetch
RUN node_modules/.bin/esy build-dependencies

# Build project
ADD . .
RUN node_modules/.bin/esy build

FROM alpine:3.12 as run

RUN apk add --update libev

COPY --from=build /build/_esy/default/build/default/app.exe /bin/app

ENTRYPOINT /bin/app
