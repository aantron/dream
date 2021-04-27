#!/bin/bash

HOST=$1

rsync -v $HOST:playground/package-lock.json $HOST:playground/opam-switch .
rsync -rlv . $HOST:playground
rsync -v ../../docs/web/site/iosevka-regular.woff2 $HOST:playground/client/
rsync -v server/playground.service root@$HOST:/etc/systemd/system/
ssh root@$HOST chmod a-x /etc/systemd/system/playground.service

echo "If this is the fisrt sync, run as playground@$HOST in ~/playground:"
echo "  opam install --deps-only ."
echo "  opam switch export opam-switch"
echo "  npm install"
echo "Then, as root@$HOST:"
echo "  systemctl enable playground"
