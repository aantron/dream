#!/bin/bash

set -e
set -x

sudo systemctl daemon-reload
sudo systemctl stop playground
(cd /home/playground/playground && sudo -H -u playground bash server/build.sh)
sudo cp /home/playground/playground/_build/default/server/playground.exe /usr/local/bin/playground
sudo chown root:root /usr/local/bin/playground
sudo systemctl start playground
