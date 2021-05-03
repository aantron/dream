#!/bin/bash

HOST=$1

rsync -v $HOST:playground/package-lock.json $HOST:playground/opam-switch .
rsync -rlv . $HOST:playground
rsync -v server/playground.service root@$HOST:/etc/systemd/system/
ssh root@$HOST chmod a-x /etc/systemd/system/playground.service

function example {
  EXAMPLE=$1
  mkdir -p ./sync-temp/sandbox/$1
  cat ../$1/*.ml | sed 's/Dream\.run/Dream\.run ~interface:"0.0.0.0"/g' \
    > ./sync-temp/sandbox/$1/server.eml.ml
  touch ./sync-temp/sandbox/$1/keep
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
example i-graphql
example j-stream
example k-websocket
example w-graphql-subscription
example w-long-polling
example w-multipart-dump
example w-query
example w-server-sent-events
example w-template-stream

function example_re {
  EXAMPLE=$1
  mkdir -p ./sync-temp/sandbox/$1
  cat ../$1/*.re \
    | sed 's/Dream\.run(/Dream\.run(~interface="0.0.0.0", /g' \
    | sed 's/Dream\.run$/Dream\.run(~interface="0.0.0.0")/g' \
    > ./sync-temp/sandbox/$1/server.eml.re
  touch ./sync-temp/sandbox/$1/keep
}
example_re r-hello
example_re r-template
example_re r-template-stream
example_re r-graphql

rsync -rlv ./sync-temp/sandbox $HOST:playground
rm -rf sync-temp

echo
echo "If this is the first sync, run as playground@$HOST in ~/playground:"
echo "  opam install --deps-only ."
echo "  opam switch export opam-switch"
echo "  npm install"
echo "Then, as root@$HOST:"
echo "  systemctl enable playground"
