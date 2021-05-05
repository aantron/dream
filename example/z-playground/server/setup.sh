#!/bin/bash

# Upon getting a fresh Droplet (virtual machine), the system packages inside the
# image it was made from are likely somewhat out of date. Upgrade them
# immediately.
sudo apt update
sudo apt -y upgrade

# A restart is likely needed, as there is often a kernel upgrade.
sudo init 6

# Install the latest Docker. We use an APT repository for the absolute latest
# release, including all the latest security features. The commands are based on
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt install -y docker-ce

# Install packages required for building OCaml projects and opam, including a C
# compiler as part of build-essential.
sudo apt install -y build-essential m4 unzip bubblewrap pkg-config

# Install opam itself.
wget -O opam https://github.com/ocaml/opam/releases/download/2.0.8/opam-2.0.8-x86_64-linux
sudo mv opam /usr/local/bin/
sudo chmod a+x /usr/local/bin/opam

# Install npm, which we use to build the client.
sudo apt install -y npm

# Install system libraries that will be needed by Dream.
sudo apt install -y libev-dev libsqlite3-dev libssl-dev pkg-config

# Create users. User playground is used for building and running the playground.
# The reason there isn't a separate user for buulding it is that the playground
# itself will use the build setup to build the sandboxes. User sandbox is for
# the containers.
sudo adduser --disabled-password playground
sudo usermod -a -G docker playground
sudo -H -u playground mkdir /home/playground/.ssh -m 700
sudo cp .ssh/authorized_keys /home/playground/.ssh/
sudo chown playground:playground /home/playground/.ssh/authorized_keys
sudo adduser --system sandbox

# Initialize opam and install a compiler.
sudo -H -u playground opam init --no-setup --bare
sudo -H -u playground opam switch create 4.12.0

# Set up UFW.
sudo ufw allow ssh
sudo ufw allow http
sudo ufw enable
