#!/bin/bash

HOST=$1

rm -rf sandbox
rsync -rlv . $HOST:playground
rsync -v ../../docs/web/site/iosevka-regular.woff2 $HOST:playground/client/
# ssh $HOST chmod a-x 'playground/*' 'playground/.*'
# ssh $HOST opam exec -- dune build playground/playground.exe
