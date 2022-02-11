# `w-nginx`

<br>

This example shows how to use [nginx](https://docs.nginx.com/) as a reverse
proxy with Dream. Both nginx and our Dream app run inside
[Docker](https://en.wikipedia.org/wiki/Docker_(software)) containers, using
[Docker Compose](https://docs.docker.com/compose/).

There are several reasons to use Dream with a reverse proxy. For example, nginx
can be used as a [load
balancer](https://nginx.org/en/docs/http/load_balancing.html). However, in this
example, we
[offload](https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/)
static asset handling to nginx. When a request comes in for a file in
`/assets/`, nginx responds with a file from `/www/assets/` inside its
container, and does not forward the request to our Dream server at all:

```nginx
http {
    server {
        listen 8080;

        root /www;
        location /assets/ {
        }

        location / {
            proxy_pass http://dream:8081;
        }
    }

    include    /etc/nginx/mime.types;
    access_log /dev/stdout;
    error_log  /dev/stderr;
}

user      nginx;
error_log /var/log/nginx/error.log notice;
pid       /var/run/nginx.pid;

events {
}
```

The reference for
[`nginx.conf`](https://github.com/aantron/dream/blob/master/example/w-nginx/nginx.conf)
can be found [here](https://nginx.org/en/docs/).

Our
[`docker-compose.yml`](https://github.com/aantron/dream/blob/master/example/w-nginx/docker-compose.yml)
just declares our two containers, connects them together, and makes the right
files visible to nginx:

```yml
version: "3"

services:
  nginx:
    image: nginx
    ports:
      - "8080:8080"
    links:
      - dream
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./assets:/www/assets

  dream:
    build: .
    restart: always
    logging:
      driver: ${LOGGING_DRIVER:-json-file}
```

...and our Dream app just serves a fixed Web page, which links to a static
image, which will be served by nginx:

```ocaml
let home =
  <html>
  <body>
    <h1>Greetings from the Dream app!</h1>
    <img
      src="/assets/camel.jpeg"
      alt="A silly camel.">
  </body>
  </html>

let () =
  Dream.run ~interface:"0.0.0.0" ~port:8081
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _request -> Dream.html home)
  ]
```

To build, run:

<pre><code><b>$ cd example/w-nginx</b>
<b>$ docker-compose build</b>
<b>$ docker-compose up</b></code></pre>

The first build will take several minutes. Once it is done, visit the
application at [`http://localhost:8080`](http://localhost:8080)!

<br>

For debugging, you may sometimes want to bypass nginx and access the Dream app
directly. To do so, add a `ports` directive to the `dream` container in
[`docker-compose.yml`](https://github.com/aantron/dream/blob/master/example/w-nginx/docker-compose.yml):

```yml
  dream:
    ports:
      - "8081:8081"
```

You can then connect to the app server at
[`http://localhost:8081`](http://localhost:8081). Note that if you do so, you
will not see the static image, because this setup relies on nginx to serve it!

<br>

If you want to provide access to the app server behind another route (say,
`/app/`), this can be accomplished with a
[`rewrite`](https://nginx.org/en/docs/http/ngx_http_rewrite_module.html#rewrite)
rule, like this:

```nginx
  location / {
    rewrite ^/app/(.*) /$1 break;
    proxy_pass http://dream:8080;
  }
```

<br>

To view logs from the Web server container only, without having them mixed with
the nginx logs, run

```
docker-compose up -d
docker-compose logs web -f
```

<br>

**See also:**

- [**`f-static`**](../f-static#files) has Dream serve static files on its own,
  without a reverse proxy.
- [**`z-docker-esy`**](../z-docker-esy#files) deploys to Digital Ocean with
  Docker Compose and esy, including Docker installation instructions.
- [**`z-docker-opam`**](../z-docker-opam#files) deploys with Docker Compose and
  opam.

<br>

[Up to the example index](../#examples)
