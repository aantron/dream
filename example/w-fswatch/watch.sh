#!/bin/bash

EXE=hello.exe
dune exec --root . ./$EXE &
fswatch -o hello.ml -l 2 | xargs -L1 bash -c \
  "killall $EXE || true; (dune exec --root . ./$EXE || true) &"
