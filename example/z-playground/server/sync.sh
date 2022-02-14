#!/bin/bash

set -e
set -x

HOST=$1
DIR=playground/example/z-playground

rsync -v $HOST:$DIR/package-lock.json $HOST:$DIR/opam-switch . || true
rsync -rlv --exclude node_modules \
  ../../dream*.opam ../../dune-project ../../src $HOST:playground
ssh $HOST "mkdir -p $DIR"
rsync -rlv . $HOST:$DIR

set +x

mkdir -p ./sync-temp/runtime
echo "let list = [" > ./sync-temp/runtime/examples.ml

function index_example {
  EXAMPLE=$1
  echo "  \"$EXAMPLE\";" >> ./sync-temp/runtime/examples.ml
}

function example {
  EXAMPLE=$1
  mkdir -p ./sync-temp/sandbox/$1
  cat ../$1/*.ml | sed 's/Dream\.run/Dream\.run ~interface:"0.0.0.0"/g' \
    > ./sync-temp/sandbox/$1/server.eml.ml
  touch ./sync-temp/sandbox/$1/keep
  index_example $EXAMPLE
}
example 1-hello
example 2-middleware
example 3-router
example 4-counter
example 5-promise
example 6-echo
example 7-template
example 8-debug
example 9-error
example a-log
example b-session
example c-cookie
example d-form
example e-json
example g-upload
example h-sql
example i-graphql
example j-stream
example k-websocket
example w-query
example w-flash
example w-tyxml
example w-chat
example w-graphql-subscription
example w-long-polling
example w-server-sent-events
example w-template-logic
example w-template-stream
example w-upload-stream
example w-content-security-policy
example w-multipart-dump
touch ./sync-temp/sandbox/w-tyxml/no-eml
mv ./sync-temp/sandbox/w-tyxml/server.eml.ml \
  ./sync-temp/sandbox/w-tyxml/server.ml

function example_re {
  EXAMPLE=$1
  mkdir -p ./sync-temp/sandbox/$1
  cat ../$1/*.re \
    | sed 's/Dream\.run(/Dream\.run(~interface="0.0.0.0", /g' \
    | sed 's/Dream\.run$/Dream\.run(~interface="0.0.0.0")/g' \
    > ./sync-temp/sandbox/$1/server.eml.re
  touch ./sync-temp/sandbox/$1/keep
  index_example $EXAMPLE
}
example_re r-hello
example_re r-template
example_re r-template-logic
example_re r-template-stream
example_re r-graphql
example_re r-tyxml
touch ./sync-temp/sandbox/r-tyxml/no-eml
mv ./sync-temp/sandbox/r-tyxml/server.eml.re \
  ./sync-temp/sandbox/r-tyxml/server.re

echo "]" >> ./sync-temp/runtime/examples.ml

cp ../h-sql/db.sqlite ./sync-temp/

set -x

rsync -rlv ./sync-temp/* $HOST:$DIR
rm -rf sync-temp
ssh $HOST "touch playground/dune-workspace"

set +x

echo
echo "If this is the first sync, run as playground@$HOST in ~/playground:"
echo "  opam install --deps-only ./dream-pure.opam ./dream-httpaf.opam ./dream.opam"
echo "  opam switch export opam-switch"
echo "  npm install"
echo "Then, as root@$HOST:"
echo "  systemctl enable playground"
