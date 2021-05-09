#!/bin/bash

set -e
set -x

sudo cp \
  /home/playground/playground/example/z-playground/server/playground.service \
  /etc/systemd/system
sudo chmod a-x /etc/systemd/system/playground.service
sudo systemctl daemon-reload
sudo systemctl stop playground
(cd /home/playground/playground/example/z-playground \
  && sudo -H -u playground bash server/build.sh)
sudo cp \
  /home/playground/playground/_build/default/example/z-playground/server/playground.exe \
  /usr/local/bin/playground
sudo chown root:root /usr/local/bin/playground
sudo systemctl start playground
