# `z-docker-esy`

<br>

This example wraps a very simple Web app in a
[Docker](https://en.wikipedia.org/wiki/Docker_(software)) container, and runs
it persistently, as a daemon.

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ ->
      Dream.html "Dream started by Docker Compose, built with esy!");
  ]
```

It uses [Docker Compose](https://docs.docker.com/compose/), so that you can
quickly expand it by adding databases and other services.

```yaml
version: "3"

services:
  web:
    build: .
    ports:
    - "80:8080"
    restart: always
    logging:
      driver: ${LOGGING_DRIVER:-json-file}
```

The example app is running live at
[http://docker-esy.dream.as](http://docker-esy.dream.as).

The setup can be run locally or on any server provider. We will use a [Digital
Ocean](https://digitalocean.com) "droplet" (virtual machine). The server binary is built by Docker.

The
[`Dockerfile`](https://github.com/aantron/dream/blob/master/example/z-docker-esy/Dockerfile)
has two stages: one for building our application, and one for the runtime that
only contains the final binary and its run-time dependencies.

<br>

## Droplet setup

Visit [Digital Ocean](https://digitalocean.com) and create an account, then
create a droplet. Simple Dream apps can be built on the smallest and cheapest
droplets as of May 2021, but you may eventually need more memory. Be sure to
enable monitoring and add your public SSH key.

Once the droplet starts, Digital Ocean will display its IP. We will use
`my-droplet` as a stand-in in the example.

SSH into your droplet:

```
$ ssh root@my-droplet
```

Then, update the droplet:

```
$ apt update
$ apt upgrade -y
```

There was likely a kernel update, so restart the droplet:

```
$ init 6
$ ssh root@my-droplet
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
$ curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

At this point, you may want to create a non-root user for running your builds,
We add this user to the `docker` group, so that it can build and start Docker
containers, and give it the same SSH public key:

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
in
[`deploy.sh`](https://github.com/aantron/dream/blob/master/example/z-docker-esy/deploy.sh)
remotely:

```
$ rsync -rlv . build@my-droplet:app --exclude _esy --exclude node_modules
$ ssh build@my-droplet "cd app && bash deploy.sh"
```

[`deploy.sh`](https://github.com/aantron/dream/blob/master/example/z-docker-esy/deploy.sh)
looks like this:

```bash
#!/bin/bash

set -e
set -x

docker-compose build
docker-compose down
docker-compose up --detach
```

The app should now be publicly accessible at the droplet's IP. Logs can be
viewed with

```
$ ssh build@my-droplet "journalctl -f"
```

<br>

## Automation

The Dream repo has a
[GitHub action](https://github.com/aantron/dream/blob/master/.github/workflows/docker-esy.yml)
that deploys this example to [docker-esy.dream.as](http://docker-esy.dream.as)
on every push. It runs the [two commands](#deploy) above.

The action needs SSH access to the droplet. See
[*Automation*](../z-systemd#automation) in
[**`z-systemd`**](../z-systemd#automation) for discussion. The only difference
is that we need don't need to upload the SSH key to user `root`, because we
don't need to log in as `root` to start a daemon:

```
$ ssh-keygen -t rsa -b 4096 -f github-actions
$ ssh build@my-droplet "cat - >> .ssh/authorized_keys" < github-actions.pub
```

And this example uses a `known_hosts` secret named
`DIGITALOCEAN_DOCKER_ESY_KNOWN_HOSTS` rather than
`DIGITALOCEAN_SYSTEMD_KNOWN_HOSTS`, but you can pick any name you like for your
version of the deploy script.

<br>

**See also:**

- [**`z-docker-opam`**](../z-docker-opam#files) is a variant of this example
  that uses opam instead of esy.
- [**`z-systemd`**](../z-systemd#files) packages the app as a systemd daemon,
  outside of a Docker container.
- [**`z-heroku`**](../z-heroku#files) deploys the app to
  [Heroku](https://heroku.com).

<br>

[Up to the example index](../#deploying)
