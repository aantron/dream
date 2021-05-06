# `z-systemd`

<br>

This example turns a Dream app into a
[systemd](https://en.wikipedia.org/wiki/Systemd) service (daemon). The app runs
in the background, and starts on system startup.

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

The application listens directly on port 80:

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0" ~port:80
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Good morning, world!");
  ]
  @@ Dream.not_found

```

The service can be hosted on any server provider. We will use [Digital
Ocean](https://www.digitalocean.com) in this example. We will run the build
remotely. If you have an Ubuntu or compatible system, you can also build locally
and send only binaries to the server. This will simplify the server setup
slightly, as it won't need an OCaml/Reason build system.

<br>

## Droplet setup

Go to [digitalocean.com](https://www.digitalocean.com) and sign up for an
account. Create a droplet (virtual machine). The smallest and cheapest droplet
type will do for the example. Be sure to set your public SSH key, and enable
monitoring.

Once the droplet is ready, Digital Ocean will show its IP address. The example
will use 127.0.0.1 as a stand-in. You can also give it a name in
`~/.ssh/config`:

```
Host my-droplet
    Hostname 127.0.0.1
    User build
```

Log in to your dropet:

```
$ ssh root@127.0.0.1
```

Update packages on the droplet, as the image from which it was built may have
been created quite a while ago. There will likely be a kernel update during this
first update, so we also retart the droplet.

```
$ apt update
$ apt upgrade -y
$ init 6
$ ssh root@127.0.0.1
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

To deploy to the droplet, we send the sources, and then run `build.sh` and
`deploy.sh` on it:

```
$ rsync -rlv . build@127.0.0.1:app --exclude _esy --exclude node_modules
$ ssh build@127.0.0.1 "cd app && bash build.sh"
$ ssh root@127.0.0.1 "bash /home/build/app/deploy.sh"
```

`build.sh`:

```sh
#!/bin/bash

set -e
set -x

[ -f node_modules/.bin/esy ] || npm install esy
rm -f app.exe
npx esy
npx esy cp '#{self.target_dir}/default/app.exe' .
```

`deploy.sh`:

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
$ ssh build@127.0.0.1 "journalctl -f"
```

<br>

[Return to the example index](../#deploying)
