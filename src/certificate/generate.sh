#! /usr/bin/env bash

set -e

openssl req -days 2922 -x509 -out localhost.crt -keyout localhost.key \
  -newkey rsa:2048 -nodes -sha256 -config localhost.cnf

openssl x509 -in localhost.crt -text -noout
