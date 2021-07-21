# `w-nginx`

<br>

This example shows how to use [nginx](https://nginx.org/en/) as a
reverse proxy together with Dream. To simplify setup, the example runs
both nginx and Dream in
[Docker](https://en.wikipedia.org/wiki/Docker_(software)) containers
with [Docker Compose](https://docs.docker.com/compose/).

<br>

There are several reasons to pair Dream with a reverse proxy. In this
example, we allow nginx to handle requests for static assets before
they reach the application server.

<br>

```ocaml
let body =
  <html>
  <body>
    <h1>Greetings from the Dream Server!</h1>
    <image src="/static/ocaml.png" alt="The OCaml logo.">
    </body>
  </html>


let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _request -> Dream.html body)
  ]
  @@ Dream.not_found
```
<br>

To build, run:

<pre><code><b>$ cd example/w-nginx</b>
<b>$ docker-compose build</b>
<b>$ docker-compose up</b></code></pre>

This will build and start the [two
containers](https://github.com/aantron/dream/blob/master/example/w-nginx/docker-compose.yml),
one for nginx and one for the application server. The first build of
will take several minutes. Later builds will be faster, due to
caching.

Visit [`http://localhost:8080`](http://localhost:8080) to reach the
application server directly. Notice how an image (the static asset)
fails to load and we just see the alt text, "The OCaml logo."

Now, visit [`http://localhost:8081`](http://localhost:8081). This
time, we get to see the lovely OCaml logo as part of the page because
nginx passes the request for `/` through to the application server and
handles the request for `/static/ocaml.png` on its own.

<br>

Tips:

- If you modify
  [`server.eml.ml`](https://github.com/aantron/dream/blob/master/example/w-nginx/server.eml.ml),
  run

  ```
  docker-compose build && docker-compose up web
  ```

- To view the logs from the Web server container only, without having them mixed
  with the nginx logs, run

  ```
  docker-compose up -d
  docker-compose logs web -f
  ```

<br>

**See also:**

- [**`z-docker-esy`**](../z-docker-esy#files) deploys to Digital Ocean with
  Docker Compose and esy, including Docker installation instructions.
- [**`z-docker-opam`**](../z-docker-opam#files) deploys with Docker Compose and
  opam.

<br>

[Up to the example index](../#examples)
