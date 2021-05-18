#!/bin/bash

set -e

EXAMPLE=2-middleware
REPO=https://github.com/aantron/dream
if [ "$1" == "" ]
then
  REF=master
else
  REF=$1
  echo Using ref $REF
fi

echo
echo -e "\e[0m✅ Creating example directory ./$EXAMPLE\e[0m"
echo
echo 💲 mkdir $EXAMPLE
mkdir $EXAMPLE
cd $EXAMPLE

echo
echo
echo
echo -e "\e[0m✅ Fetching example files with git\e[0m"
echo -e "\e[0m   Source: $REPO/tree/$REF/example/$EXAMPLE#files\e[0m"
mkdir clone
cd clone
git init --quiet
git remote add origin $REPO.git
git config --local core.sparseCheckout true
echo example/$EXAMPLE >> .git/info/sparse-checkout
git pull origin $REF --depth 1 --quiet
cd ..
mv clone/example/$EXAMPLE/* .
rm -rf clone

echo
echo
echo
echo -e "\e[0m✅ Installing esy in ./$EXAMPLE\e[0m"
echo -e "\e[0m   esy (https://esy.sh/) is an npm-like package manager for native code\e[0m"
echo
echo 💲 npm install esy
npm --silent install esy

echo
echo
echo -e "\e[0m✅ Building and installing native dependencies in ./$EXAMPLE\e[0m"
echo -e "\e[0m   This can take a few minutes the first time\e[0m"
echo
echo 💲 npx esy
npx esy

echo
echo
echo
echo -e "\e[0m✅ Building and running example\e[0m"
echo
echo 💲 npx esy start
echo
npx esy start

echo
echo
echo
echo ❗ To completely delete everything touched by this Quick Start script, run
echo
echo "     rm" -rf ./$EXAMPLE "~/.esy"
echo
echo "   To" re-run the server instead, \`cd ./$EXAMPLE\`, and just repeat
echo
echo "     npx esy start"
echo
echo "   If" you change the code, \`npx esy start\` will rebuild the server automatically.
echo "   The" built server binary can be copied out with:
echo
echo "     cd ./$EXAMPLE"
echo "     npx esy cp '#{self.target_dir}/default/middleware.exe' ."
echo
echo "   See:"
echo
echo "   - This example:" $REPO/tree/$REF/example/$EXAMPLE#files
echo "   - Tutorial:    " $REPO/tree/$REF/example#tutorial
echo
