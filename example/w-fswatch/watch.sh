#!/bin/bash

npx esy start &
fswatch -o hello.ml -l 2 | xargs -L1 bash -c \
  "killall hello.exe || true; (npx esy start || true) &"
