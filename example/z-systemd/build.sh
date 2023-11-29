#!/bin/bash

set -e
set -x

rm -f app.exe
dune build
cp _build/default/app.exe .
