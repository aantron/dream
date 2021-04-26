#!/bin/bash

sudo apt update
sudo apt upgrade
# sudo init 6

# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
sudo apt install apt-transport-https
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt install docker-ce

sudo apt install build-essential m4 unzip bubblewrap
wget -O opam https://github.com/ocaml/opam/releases/download/2.0.8/opam-2.0.8-x86_64-linux
sudo mv opam /usr/local/bin/
sudo chmod a+x /usr/local/bin/opam
opam init --no-setup --bare
opam update
opam switch create 4.12.0

sudo apt install libev-dev libssl-dev pkg-config
opam install dream

sudo apt install npm
npm install
