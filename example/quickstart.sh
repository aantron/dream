#!/bin/bash

set -e

EXAMPLE=2-middleware
EXE=middleware.exe
DIRECTORY=dream-project
REPO=https://github.com/aantron/dream
if [ "$1" == "" ]
then
  REF=master
else
  REF=$1
  echo Using ref $REF
fi

if ! (which git >> /dev/null)
then
  echo
  echo -e "\e[0m🛑 'git' command missing \e[0m"
  echo -e "\e[0m   Please install git from your system package manager\e[0m"
  exit 1
fi

if ! (which opam >> /dev/null)
then
  echo
  echo -e "\e[0m🛑 'opam' command missing \e[0m"
  echo -e "\e[0m   Please install opam by visiting\e[0m"
  echo -e "\e[0m   https://opam.ocaml.org/doc/Install.html\e[0m"
  echo -e "\e[0m   ...and run 'opam init'"
  exit 1
fi

echo
echo -e "\e[0m✅ Creating directory './$DIRECTORY'\e[0m"
echo
echo 💲 mkdir $DIRECTORY
mkdir $DIRECTORY
echo 💲 cd $DIRECTORY
cd $DIRECTORY

echo
echo -e "\e[0m✅ Fetching example files using git\e[0m"
echo -e "\e[0m   Source: $REPO/tree/$REF/example/$EXAMPLE#folders-and-files\e[0m"
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
echo -e "\e[0m✅ Building and installing dependencies\e[0m"
echo -e "\e[0m   This can take a few minutes\e[0m"
echo
echo 💲 opam switch create . 5.1.0 --no-install --yes
opam switch create . 5.1.0 --no-install --yes
echo 💲 'eval `opam env`'
eval `opam env`
echo 💲 opam install . --deps-only --yes
opam install . --deps-only --yes

echo
echo -e "\e[0m✅ Building and running example\e[0m"
echo -e "\e[0m✅ When building yourself, be sure to run\e[0m"
echo
echo '     eval `opam env`'
echo
echo -e "\e[0m✅ The built server binary can be copied out with\e[0m"
echo
echo "     cp _build/default/$EXE ."
echo
echo -e "\e[0m✅ To rebuild automatically when source files change, run\e[0m"
echo
echo "     dune exec ./$EXE --watch"
echo
echo -e "\e[0m✅ See\e[0m"
echo
echo "   - This example:" $REPO/tree/$REF/example/$EXAMPLE#folders-and-files
echo "   - Tutorial:    " $REPO/tree/$REF/example#tutorial
echo
echo 💲 dune exec ./$EXE
echo
dune exec ./$EXE
