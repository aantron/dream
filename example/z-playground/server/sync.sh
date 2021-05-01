#!/bin/bash

HOST=$1

rsync -v $HOST:playground/package-lock.json $HOST:playground/opam-switch .
rsync -rlv . $HOST:playground
rsync -v ../../docs/web/site/iosevka-regular.woff2 $HOST:playground/client/
rsync -v server/playground.service root@$HOST:/etc/systemd/system/
ssh root@$HOST chmod a-x /etc/systemd/system/playground.service

shopt -s nullglob

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

rsync -rlv ./sync-temp/sandbox $HOST:playground
rm -rf sync-temp

echo "If this is the first sync, run as playground@$HOST in ~/playground:"
echo "  opam install --deps-only ."
echo "  opam switch export opam-switch"
echo "  npm install"
echo "Then, as root@$HOST:"
echo "  systemctl enable playground"
