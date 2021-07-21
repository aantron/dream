FROM debian:stable-slim as build

RUN apt-get update
RUN apt-get install -y curl git libpq-dev m4 npm unzip

WORKDIR /build

RUN npm install esy

# Install dependencies.
ADD esy.* .
RUN [ -f esy.lock ] || node_modules/.bin/esy solve
RUN node_modules/.bin/esy fetch
RUN node_modules/.bin/esy build-dependencies

# Build project.
ADD . .
RUN node_modules/.bin/esy build



FROM debian:stable-slim as run

RUN apt-get update
RUN apt-get install -y libev4 libpq5 libssl1.1

COPY --from=build /build/_esy/default/build/default/postgres.exe /bin/postgres

ENTRYPOINT /bin/postgres
