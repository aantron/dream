# `z-systemd`

<br>

This example turns a Dream app into a
[systemd](https://en.wikipedia.org/wiki/Systemd) service (daemon). The app runs
in the background, and starts on system startup:

```ini
[Unit]
Description=Dream systemd example
After=network.target

[Service]
Type=simple
User=app
Restart=on-failure
RestartSec=1
StandardOutput=journal
WorkingDirectory=/home/app
ExecStart=/home/build/app/app.exe
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

The service listens directly on port 80:

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0" ~port:80
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Dream started by systemd!");
  ]
```

It is live at [http://systemd.dream.as](http://systemd.dream.as). As a second
example, the [playground](http://dream.as) is deployed as a [systemd
service](https://github.com/aantron/dream/blob/master/example/z-playground/server/playground.service).

The service can be hosted on any server provider. We will use [Digital
Ocean](https://www.digitalocean.com) in this example. We will run the build
remotely, taking advantage of the remote filesystem as a build cache. If you
have an Ubuntu or compatible system, you can also build locally and send only
binaries to the server. This will simplify the server setup slightly, as it
won't need an OCaml/Reason build system.

To complete the setup, we [add a CD script](#automation) at the end. It deploys
the example to [systemd.dream.as](http://systemd.dream.as) each time the code is
pushed!

<br>

## Droplet setup

Go to [digitalocean.com](https://www.digitalocean.com) and sign up for an
account. Create a droplet (virtual machine). The smallest and cheapest droplet
type will do for the example. Be sure to include your public SSH key, and enable
monitoring.

Once the droplet is ready, Digital Ocean will show its IP address. This text
will use `my-droplet` as a stand-in.

Log in to your dropet:

```
$ ssh root@my-droplet
```

Update packages on the droplet, as the image from which it was built may have
been created quite a while ago. There will likely be a kernel update, so we
also retart the droplet.

```
$ apt update
$ apt upgrade -y
$ init 6
$ ssh root@my-droplet
```

Install system packages for building the app:

```
$ apt install m4 npm unzip -y
```

Install system packages for running the app:

```
$ apt install libev4 -y
```

Create users. `build` will be used to build the app, and `app` to run it:

```
$ adduser build --disabled-password
$ adduser app --system
$ usermod build --append --groups systemd-journal
$ mkdir /home/build/.ssh -m 700
$ cp .ssh/authorized_keys /home/build/.ssh/
$ chown -R build:build /home/build/.ssh
```

Droplet setup is now done, so log out:

```
$ exit
```

<br>

## Deploy

To deploy our app, we send the sources, and then run `build.sh` and `deploy.sh`
on the droplet:

```
$ rsync -rlv . build@my-droplet:app --exclude _esy --exclude node_modules
$ ssh build@my-droplet "cd app && bash build.sh"
$ ssh root@my-droplet "bash /home/build/app/deploy.sh"
```

[`build.sh`](https://github.com/aantron/dream/blob/master/example/z-systemd/build.sh):

```sh
#!/bin/bash

set -e
set -x

[ -f node_modules/.bin/esy ] || npm install esy
rm -f app.exe
npx esy
npx esy cp '#{self.target_dir}/default/app.exe' .
```

[`deploy.sh`](https://github.com/aantron/dream/blob/master/example/z-systemd/deploy.sh):

```sh
#!/bin/bash

set -e
set -x

cp /home/build/app/app.service /etc/systemd/system/
systemctl daemon-reload
systemctl restart app
```

The app should now be running at your droplet's IP address!

To view logs, run

```
$ ssh build@my-droplet "journalctl -f"
```

<br>

## Automation

The Dream repo deploys this example to
[systemd.dream.as](http://systemd.dream.as) from a [GitHub
action](https://github.com/aantron/dream/blob/master/.github/workflows/systemd.yml),
which mainly just runs the [deploy steps](#deploy) above.

The action needs SSH access to the droplet. Generate an SSH key pair without a
passphrase, and upload the public key:

```
$ ssh-keygen -t rsa -b 4096 -f github-actions
$ ssh-copy-id -i github-actions root@my-droplet
$ ssh-copy-id -i github-actions build@my-droplet
```

Then, go to Secrets in your repository's settings, and add a secret called
`DIGITALOCEAN_SSH_KEY`, with the content of file `github-actions` (the private
key). After that, you can delete `github-actions` and `github-actions.pub`.

Create another secret `DIGITALOCEAN_SYSTEMD_KNOWN_HOSTS`, and put the output of

```
$ ssh-keyscan my-droplet
```

into it. Note that this output is not a secret. However, GitHub secrets is a
very convenient way of passing it to the action.

<br>

**See also:**

- [**`z-docker-esy`**](../z-docker-esy#files) packages the app using [Docker
  Compose](https://docs.docker.com/compose/), instead of running it directly
  with systemd.
- [**`z-heroku`**](../z-heroku#files) deploys the app to
  [Heroku](https://heroku.com).

<br>

[Up to the example index](../#deploying)
