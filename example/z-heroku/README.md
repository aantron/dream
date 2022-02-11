# `z-heroku`

<br>

This example deploys a very simple Dream
[application](https://github.com/aantron/dream/blob/master/example/z-heroku/app.ml)
to [Heroku](https://www.heroku.com/). A low-usage app can be hosted for
[free](https://www.heroku.com/pricing). Heroku has an easy-to-use CLI and
[scaling](https://devcenter.heroku.com/articles/scaling) options. The drawback
is that it imposes some constraints on your app, such as no persistent local
state. Many apps satisfy these constraints, however.

The code is essentially example
[**`2-middleware`**](../2-middleware#files), but Heroku will pass the desired
port number in environment variable `PORT`, so we read it:

```ocaml
let () =
  Dream.run ~interface:"0.0.0.0" ~port:(int_of_string (Sys.getenv "PORT"))
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html "Dream running in Heroku!");
  ]
```

It is running at
[https://dream-example.herokuapp.com/](https://dream-example.herokuapp.com/).

<br>

We suggest a deployment process that is out of the norm for Heroku. Heroku is
designed to build apps from source on Heroku's servers. However, Heroku does
not support OCaml. Also, a custom container that is capable of building even a
simple OCaml app in Heroku is likely to be large, difficult to maintain, and
may force a user into a higher pricing tier than is needed by the Web app
itself.

So, we build the Web server binary locally, as normal, and then send it to
Heroku. This works fine if you and your developers are on an Ubuntu or similar
systems. If you need to support something else, we suggest building an
executable in either a container or in CI, using almost the same instructions.
See the
[GitHub Actions workflow](https://github.com/aantron/dream/blob/master/.github/workflows/heroku.yml)
that deploys this example. `heroku local`, mentioned later, probably runs
cross-platform.

Do a normal local build, or build in a container or in CI:

```
$ npm install esy
$ npx esy
```

and then

```
$ npx esy build
```

For opam,

```
$ dune build --root . ./app.exe
```

<br>

With Heroku, there are two new pieces of boilerplate to consider. The
[`Procfile`](https://github.com/aantron/dream/blob/master/example/z-heroku/Procfile)
tells Heroku what we would like to run. In this example, it's just one Web
server:

```
web: deploy/app.exe
```

[`.slugignore`](https://github.com/aantron/dream/blob/master/example/z-heroku/.slugignore) tells the `heroku` CLI not to upload all of our intermediate build
artifacts, dependencies, etc., to Heroku, which saves a huge amount of time on
deploy:

```
_build/
_esy/
node_modules/
esy.lock/
```

Instead, we copy only our final binary out of these directories, and put it in
a separate, clean directory `./deploy/`. With esy:

```
$ mkdir -p deploy
$ npx esy cp '#{self.target_dir}/default/app.exe' deploy/
```

with opam:

```
$ mkdir -p deploy
$ cp _build/default/app.exe deploy/
```

If you have a large amount of code, it may be easier to move `Procfile` into
`deploy` and run `heroku` from there, rather than using `.slugignore`.

<br>

Now the Heroku part. Go to [heroku.com](https://www.heroku.com/) and sign up
for a free account. Then,
[install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install)
the `heroku` CLI, and create your Heroku app:

```
$ heroku login -i
$ heroku create my-app
$ heroku buildpacks:set http://github.com/ryandotsmith/null-buildpack.git --app my-app
$ heroku plugins:install heroku-builds
```

Replace `my-app` by something else; Heroku apps are in a global namespace!

At this point, you may want to test the Heroku setup
[locally](https://devcenter.heroku.com/articles/heroku-local):

```
$ heroku local
```

If all is well, attach to the Heroku log in a different terminal window:

```
$ heroku logs --tail --app my-app
```

...and send your binary over!

```
$ heroku builds:create --app my-app
```

Heroku will print a link to your running app, something similar to

```
-----> Building on the Heroku-20 stack
-----> Deleting 3 files matching .slugignore patterns.
-----> Using buildpack: http://github.com/ryandotsmith/null-buildpack.git
-----> Null Buildpack app detected
-----> Nothing to compile
-----> Discovering process types
       Procfile declares types -> web

-----> Compressing...
       Done: 3.8M
-----> Launching...
       Released v3
       https://my-app.herokuapp.com/ deployed to Heroku
```

<br>

That's it! Just repeat your build command, `cp` to `deploy/`, and
`heroku builds:create`. Continue to the
[Heroku documentation](https://devcenter.heroku.com/categories/reference) for a
full reference.

<br>

These instructions are clearly not as convenient for users on macOS or Windows
outside WSL. All suggestions and improvements are welcome. Also, fully usable
logs and full cookie security in Heroku probably require
[#10 *Add trust_proxy_headers middleware*](https://github.com/aantron/dream/issues/10).

<br>

These instructions are substantially based on [*Deploying OCaml server on
Heroku*](https://medium.com/@aleksandrasays/deploying-ocaml-server-on-heroku-f91dcac11f11)
by Aleksandra Sikora.

<br>

**See also:**

- [**`z-docker-esy`**](../z-docker-esy#files) deploys to a dedicated server,
  with the Web application managed by Docker Compose.
- [**`z-systemd`**](../z-systemd#files) deploys to a dedicated server, running
  the Web application as a systemd daemon.

<br>

[Up to the example index](../#deploying)
