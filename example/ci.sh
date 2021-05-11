#!/bin/bash

set -e

EXAMPLES=$(find example -maxdepth 1 -type d | grep -v "^example/0" | grep -v "^example$" | sort)
shopt -s nullglob

for EXAMPLE in $EXAMPLES
do
  FILE=$(ls $EXAMPLE/*.ml $EXAMPLE/*.re $EXAMPLE/server/*.ml $EXAMPLE/server/*.re)
  EXE=$(echo $FILE | sed 's/\..*$/.exe/g')
  echo dune build $EXE
  dune build $EXE
done
