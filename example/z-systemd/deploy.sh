#!/bin/bash

set -e
set -x

cp /home/build/app/app.service /etc/systemd/system/
systemctl daemon-reload
systemctl restart app
