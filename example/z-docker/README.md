# `z-docker`

<br>

This example wraps a very simple Web app in a [Docker](https://www.docker.com/)
container, and runs it persistently, as a daemon.

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Good morning, world!");
  ]
  @@ Dream.not_found
```

It uses [Docker Compose](https://docs.docker.com/compose/), so that you can
quickly expand it by adding databases and the like.

```yaml
version: "3"

services:
  web:
    build: .
    ports:
    - "80:8080"
    restart: always
    logging:
      driver: journald
```

The setup can be run on any server provider. We will use a [Digital
Ocean](https://digitalocean.com) "droplet" (virtual machine) running Ubuntu
20.04, and build the app from source on the droplet. If you are using Ubuntu or
a compatible operating system, you could also build locally, and send only
assets and binaries. This will reduce the amount of setup needed on the
droplet, since it won't need an OCaml or Reason build system.

<br>

## Droplet setup

Visit [Digital Ocean](https://digitalocean.com) and create an account, then
create a droplet. Simple Dream apps can be built on the smallest and cheapest
droplets as of May 2021, but you may eventually need more memory. Be sure to
enable monitoring and add your public SSH key.

Once the droplet starts, Digital Ocean will display its IP. We will use
`127.0.0.1` as a stand-in in the example. You can assign a name to it in
`~/.ssh/config`:

```
Host my-droplet
    Hostname 127.0.0.1
    User build
```

SSH into your droplet:

```
$ ssh root@127.0.0.1
```

Then, install update the droplet:

```
$ apt update
$ apt upgrade -y
```

If you get messages about a kernel upgrade, and `uname -r` is still showing the
older kernel, you may want to restart the droplet:

```
$ init 6
$ ssh root@127.0.0.1
```

[Install Docker](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04):

```
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
$ add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
$ apt update
$ apt install docker-ce -y
```

[Install Docker Compose](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04).
Check [here](https://github.com/docker/compose/releases) for the latest
available release.

```
$ curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

Install npm, which we will later use for esy, and system dependencies:

```
$ apt install m4 npm unzip -y
```

At this point, you may want to create a non-root user for running your builds,
depending on the nature of your application, how much you trust dependencies,
and other considerations. We add this user to the `docker` group, so that it can
start Docker containers, and give it the same SSH public key:

```
$ adduser build --disabled-password
$ usermod build --append --groups docker
$ usermod build --append --groups systemd-journal
$ mkdir /home/build/.ssh -m 700
$ cp .ssh/authorized_keys /home/build/.ssh/
$ chown -R build:build /home/build/.ssh
```

Droplet setup is now complete:

```
$ exit
```

<br>

## Deploy

To deploy to the droplet, we send the sources over, and trigger the commands
in `deploy.sh` remotely:

```
$ rsync -rlv . build@127.0.0.1:app --exclude _esy --exclude node_modules
$ ssh build@127.0.0.1 "cd app && bash deploy.sh"
```

`deploy.sh` looks like this:

```sh
#!/bin/bash

set -e
set -x

[ -f node_modules/.bin/esy ] || npm install esy
rm -f app.exe
npx esy
npx esy cp '#{self.target_dir}/default/app.exe' .
docker-compose build
docker-compose down
docker-compose up --detach
```

The app should now be publicly accessible at the droplet's IP. Logs can be
viewed with

```
$ ssh root@127.0.0.1 "journalctl -f"
```

<br>

[Return to the example index](../#deploying)
