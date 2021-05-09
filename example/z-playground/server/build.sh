#!/bin/bash

set -e
set -x

mkdir -p static
cp node_modules/codemirror/lib/codemirror.js static/
cp node_modules/codemirror/lib/codemirror.css static/
cp node_modules/codemirror/theme/material.css static/
cp node_modules/codemirror/mode/mllike/mllike.js static/
cp client/playground.css static/
cp client/playground.js static/
opam exec -- dune build server/playground.exe
