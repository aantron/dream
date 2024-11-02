# Tutorial

Dream's first several examples make up a **tutorial**. Each example is a
complete project with a helpful README, and plenty of links to next steps and
documentation. You can begin at [**`1-hello`**](1-hello#folders-and-files), or look in the
list below and jump to whatever interests you!

- [**`1-hello`**](1-hello#folders-and-files) &nbsp;&mdash;&nbsp; the simplest Dream server
  responds to every request with the same friendly message.
- [**`2-middleware`**](2-middleware#folders-and-files) &nbsp;&mdash;&nbsp; adds the first
  Dream middleware: the *logger*.
- [**`3-router`**](3-router#folders-and-files) &nbsp;&mdash;&nbsp; different handlers for
  different paths.
- [**`4-counter`**](4-counter#folders-and-files) &nbsp;&mdash;&nbsp; the first *custom*
  middleware!
- [**`5-promise`**](5-promise#folders-and-files) &nbsp;&mdash;&nbsp; introduces Lwt, the
  promise library used by Dream.
- [**`6-echo`**](6-echo#folders-and-files) &nbsp;&mdash;&nbsp; reads request bodies.
- [**`7-template`**](7-template#folders-and-files) &nbsp;&mdash;&nbsp; renders responses
  from inline HTML templates and guards against XSS.
- [**`8-debug`**](8-debug#folders-and-files) &nbsp;&mdash;&nbsp; includes detailed
  information about errors in responses.
- [**`9-error`**](9-error#folders-and-files) &nbsp;&mdash;&nbsp; customize all error
  responses in one place.
- [**`a-log`**](a-log#folders-and-files) &nbsp;&mdash;&nbsp; writing messages to Dream's
  log.
- [**`b-session`**](b-session#folders-and-files) &nbsp;&mdash;&nbsp; associates state with
  client sessions.
- [**`c-cookie`**](c-cookie#folders-and-files) &nbsp;&mdash;&nbsp; sets custom cookies.
- [**`d-form`**](d-form#folders-and-files) &nbsp;&mdash;&nbsp; reads forms with CSRF
  prevention.
- [**`e-json`**](e-json#folders-and-files) &nbsp;&mdash;&nbsp; sends and receives JSON
  securely.
- [**`f-static`**](f-static#folders-and-files) &nbsp;&mdash;&nbsp; serves static files from
  a local directory.
- [**`g-upload`**](g-upload#folders-and-files) &nbsp;&mdash;&nbsp; receives file uploads.
- [**`h-sql`**](h-sql#folders-and-files) &nbsp;&mdash;&nbsp; queries an SQL database.
- [**`i-graphql`**](i-graphql#folders-and-files) &nbsp;&mdash;&nbsp; serves a GraphQL
  schema and GraphiQL.
- [**`j-stream`**](j-stream#folders-and-files) &nbsp;&mdash;&nbsp; streams request and
  response bodies.
- [**`k-websocket`**](k-websocket#folders-and-files) &nbsp;&mdash;&nbsp; opens a WebSocket
  between client and server.
- [**`l-https`**](l-https#folders-and-files) &nbsp;&mdash;&nbsp; enables HTTPS and HTTP/2
  upgrades.

That's it for the tutorial!

<br>

# Reason

There are several examples showing Dream with Reason syntax.

- [**`r-hello`**](r-hello#folders-and-files) &nbsp;&mdash;&nbsp; the simplest Dream server.
- [**`r-template`**](r-template#folders-and-files) &nbsp;&mdash;&nbsp; renders HTML
  templates and protects against XSS.
- [**`r-template-files`**](r-template-files#folders-and-files) &nbsp;&mdash;&nbsp; templates
  in separate `.html` files for better editor support.
- [**`r-template-logic`**](r-template-logic#folders-and-files) &nbsp;&mdash;&nbsp; control
  flow inside templates.
- [**`r-template-stream`**](r-template-stream#folders-and-files) &nbsp;&mdash;&nbsp; streams
  templates as response bodies.
- [**`r-tyxml`**](r-tyxml#folders-and-files) &nbsp;&mdash;&nbsp; type-checked server-side
  JSX templates.
- [**`r-graphql`**](r-graphql#folders-and-files) &nbsp;&mdash;&nbsp; serves a GraphQL
  schema.

<br>

# Full-stack

- [**`r-fullstack-melange`**](r-fullstack-melange#folders-and-files) &nbsp;&mdash;&nbsp;
  server *and* client written in Reason!
- [**`w-fullstack-rescript`**](w-fullstack-rescript#folders-and-files) &nbsp;&mdash;&nbsp;
  shares OCaml code between server and client using ReScript.
- [**`w-fullstack-jsoo`**](w-fullstack-jsoo#folders-and-files) &nbsp;&mdash;&nbsp; shares
  OCaml code between server and client using js_of_ocaml.

<br>

# Deploying

- [**`z-heroku`**](z-heroku#folders-and-files) &nbsp;&mdash;&nbsp; to
  [Heroku](https://www.heroku.com).
- [**`z-fly`**](z-fly#folders-and-files) &nbsp;&mdash;&nbsp; to [Fly.io](https://fly.io/).
- [**`z-docker-esy`**](z-docker-esy#folders-and-files) &nbsp;&mdash;&nbsp; on a server,
  using Docker, with package manager esy.
- [**`z-docker-opam`**](z-docker-opam#folders-and-files) &nbsp;&mdash;&nbsp; on a server,
  using Docker, with package manager opam.
- [**`z-systemd`**](z-systemd#folders-and-files) &nbsp;&mdash;&nbsp; on a server, as a
  systemd daemon.

<br>

# Examples

The rest of the examples cover additional topics in a more standalone fashion.
The goal of the examples is to (eventually) cover the great majority of
real-world HTTP usage, so that they make up a good survey. Please open an issue
if something is missing!

<br>

- [**`w-template-files`**](w-template-files#folders-and-files) &nbsp;&mdash;&nbsp; templates
  in separate `.html` files for better editor support.
- [**`w-template-logic`**](w-template-logic#folders-and-files) &nbsp;&mdash;&nbsp; control
  flow inside templates.
- [**`w-graphql-subscription`**](w-graphql-subscription#folders-and-files)
  &nbsp;&mdash;&nbsp; GraphQL subscriptions.
- [**`w-postgres`**](w-postgres#folders-and-files) &nbsp;&mdash;&nbsp; connects to a
  PostgreSQL database.
- [**`w-flash`**](w-flash#folders-and-files) &nbsp;&mdash;&nbsp; using flash messages, which
  are displayed on the next request.
- [**`w-chat`**](w-chat#folders-and-files) &nbsp;&mdash;&nbsp; a chat room based on
  WebSockets.
- [**`w-content-security-policy`**](w-content-security-policy#folders-and-files)
  &nbsp;&mdash;&nbsp; sandboxes Web pages using `Content-Security-Policy`.
- [**`w-esy`**](w-esy#folders-and-files) &nbsp;&mdash;&nbsp; gives detail on packaging with
  [esy](https://esy.sh/), an npm-like package manager.
- [**`w-one-binary`**](w-one-binary#folders-and-files) &nbsp;&mdash;&nbsp; bakes static
  assets into a self-contained server binary.
- [**`w-watch`**](w-watch#folders-and-files) &nbsp;&mdash;&nbsp; sets up a development
  watcher.
- [**`w-live-reload`**](w-live-reload#folders-and-files) &nbsp;&mdash;&nbsp; a simple
  live-reloading setup.
- [**`w-nginx`**](w-nginx#folders-and-files) &nbsp;&mdash;&nbsp; uses nginx as a
  reverse proxy.
- [**`w-tyxml`**](w-tyxml#folders-and-files) &nbsp;&mdash;&nbsp; uses TyXML for type-checked
  HTML templating.
- [**`w-dream-html`**](../w-dream-html#folders-and-files) &nbsp;&mdash;&nbsp; uses
  dream-html for convenient HTML generation from OCaml.
- [**`w-long-polling`**](w-long-polling#folders-and-files) &nbsp;&mdash;&nbsp; old form of
  asynchronous communication without WebSockets.
- [**`w-query`**](w-query#folders-and-files) &nbsp;&mdash;&nbsp; reads URL query parameters.
- [**`w-server-sent-events`**](w-server-sent-events#folders-and-files) &nbsp;&mdash;&nbsp;
  [`EventSource`](https://developer.mozilla.org/en-US/docs/Web/API/EventSource),
  an older alternative to WebSockets.
- [**`w-template-stream`**](w-template-stream#folders-and-files) &nbsp;&mdash;&nbsp; sends
  templates asynchronously, one chunk at a time.
- [**`w-upload-stream`**](w-upload-stream#folders-and-files) &nbsp;&mdash;&nbsp; streams
  uploaded files.
- [**`w-stress-response`**](w-stress-response#folders-and-files) &nbsp;&mdash;&nbsp;
  benchmarks streaming very large responses.
- [**`w-stress-websocket-send`**](w-stress-websocket-send#folders-and-files)
  &nbsp;&mdash;&nbsp; benchmarks sending WebSocket messages quickly.
- [**`w-multipart-dump`**](w-multipart-dump#folders-and-files) &nbsp;&mdash;&nbsp; echoes
  `multipart/form-data` bodies for debugging.
- [**`z-playground`**](z-playground#folders-and-files) &nbsp;&mdash;&nbsp; source code of
  the Dream playground.

<br>
<br>

# Roadmap

These examples will be trickled in during the alpha releases.

Ideas:

- `w-index-html`
- `w-react-spa`
- `w-subcommand`
- `w-template-directory`
- `w-chat`
- `w-fullstack-brr`
- `w-fullstack-js`

Basics:

- `w-content-negotiation`
- [**`w-query`**](w-query#folders-and-files) &nbsp;&mdash;&nbsp; done.
- `w-scope` &nbsp;&mdash;&nbsp; for
  [`Dream.scope`](https://aantron.github.io/dream/#val-scope).
- `w-subsite` &nbsp;&mdash;&nbsp; for
  [`*` routes](https://aantron.github.io/dream/#val-router).
- `w-testing` &nbsp;&mdash;&nbsp; for
  [*Testing*](https://aantron.github.io/dream/#testing).
- `w-site-prefix` &nbsp;&mdash;&nbsp; a Web app running not at `/`.

Security:

- `w-auth`
- `w-cors`
- `w-file-session`
- `w-form-expired` &nbsp;&mdash;&nbsp; for other cases of
  [`Dream.form`](https://aantron.github.io/dream/#val-form).
- `w-json-csrf` &nbsp;&mdash;&nbsp; for
  [`Dream.csrf_token`](https://aantron.github.io/dream/#val-csrf_token) and
  `X-CSRF-Token:`.
- `w-jwt`
- `w-key-rotation` &nbsp;&mdash;&nbsp; for a to-be-added `~secrets` argument
  to [`Dream.run`](https://aantron.github.io/dream/#val-run), which can specify
  multiple decryption keys.
- `w-upload-csrf` &nbsp;&mdash;&nbsp; for
  [`Dream.csrf_token`](https://aantron.github.io/dream/#val-csrf_token) with
  [`Dream.upload`](https://aantron.github.io/dream/#val-upload).

Techniques:

- `w-etag`
- `w-graphql-sql`
- `w-graphql-mutation`
- `w-https-redirect`
- `w-sql-stream`
- `w-websocket-stream`

<!-- TODO Show self-contained example with ppx_blob. -->
