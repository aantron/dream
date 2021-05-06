#!/bin/bash

set -e
set -x

docker-compose build
docker-compose down
LOGGING_DRIVER=journald docker-compose up --detach
