#!/bin/bash

set -e
set -x

[ -f node_modules/.bin/esy ] || npm install esy
rm -f app.exe
npx esy
npx esy cp '#{self.target_dir}/default/app.exe' .
