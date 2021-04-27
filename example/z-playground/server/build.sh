#!/bin/bash

set -e
set -x

sudo systemctl daemon-reload
sudo systemctl stop playground
sudo -H -u playground bash -c "cd /home/playground/playground && opam exec -- dune build server/playground.exe"
sudo cp /home/playground/playground/_build/default/server/playground.exe /usr/local/bin/playground
sudo chown root:root /usr/local/bin/playground
sudo systemctl start playground
