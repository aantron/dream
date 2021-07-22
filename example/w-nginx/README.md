# `w-nginx`

<br>

This example shows how to use [nginx](https://docs.nginx.com/) as a
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
  <a href="http://ocaml.org">
  <img src="/static/ocaml.png"
       alt="The OCaml logo."
       style="border: none; width: 150px;" />
  </a>
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

These [nginx
docs](https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/)
discuss serving static content in more detail. Here is the server
configuration for `nginx`:

```nginx
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    access_log  /dev/stdout;
    error_log   /dev/stderr;

    keepalive_timeout  65;

    server {
        listen 8081 default_server;

        root /www/data;

        location /static/ {
            # Serve static assets from the folder /www/data/static on the
            # nginx server.
        }

        location / {
            # Forward any other request to the dream server.
            proxy_pass http://web:8080;
            proxy_read_timeout 60s;
        }
    }
}
```

To summarize, this configuration says:

- The proxy server will listen on port 8081.
- Given a request starting with `/static/`, the proxy server will look
  for an appropriate file under `/www/data/static`.
- Any other traffic gets forwarded to the `web` container on port
  8080.


Note that if you wanted to provide access to the application server
behind another route (say `/app`), this can be accomplished with a
`rewrite` rule, like this:

```nginx
  location / {
    rewrite ^/app/(.*) /$1 break;
    proxy_pass http://web:8080;
    proxy_read_timeout 60s;
  }
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

In a production setup the user shouldn't be able to reach the
application server directly. The reason we can reach the application
server on port 8080 is that this port is exposed in the
`docker-compose.yml` file. Updating the `web` container to

```yml
  web:
    build: .
    restart: always
    logging:
      driver: ${LOGGING_DRIVER:-json-file}
```

will prevent direct access to the application server.

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
- [**`f-static`**](../f-static#files) shows how to use `Dream.static` to serve files from a directory.
- [**`z-docker-esy`**](../z-docker-esy#files) deploys to Digital Ocean with
  Docker Compose and esy, including Docker installation instructions.
- [**`z-docker-opam`**](../z-docker-opam#files) deploys with Docker Compose and
  opam.

<br>

[Up to the example index](../#examples)
