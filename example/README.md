# Tutorial

<!-- Link to tutorial getting started instructions. -->

Dream's first several examples make up a **tutorial**. Each example is a
complete project with a helpful README, and plenty of links to next steps and
documentation. You can begin at [**`1-hello`**](1-hello#files), or look in the
list below and jump to whatever interests you!

- [**`1-hello`**](1-hello/#files) &nbsp;&mdash;&nbsp; the simplest Dream server
  responds to every request with the same friendly message.
- [**`2-middleware`**](2-middleware/#files) &nbsp;&mdash;&nbsp; adds the first
  Dream middleware: the *logger*.
- [**`3-router`**](3-router/#files) &nbsp;&mdash;&nbsp; different handlers for
  different paths.
- [**`4-counter`**](4-counter/#files) &nbsp;&mdash;&nbsp; the first *custom*
  middleware!
- [**`5-promise`**](5-promise/#files) &nbsp;&mdash;&nbsp; introduces Lwt, the
  promise library used by Dream.
- [**`6-echo`**](6-echo/#files) &nbsp;&mdash;&nbsp; reads request bodies.
- [**`7-template`**](7-template/#files) &nbsp;&mdash;&nbsp; renders responses
  from inline HTML templates and guards against XSS.
- [**`8-debug`**](8-debug/#files) &nbsp;&mdash;&nbsp; includes detailed
  information about errors in responses.
- [**`9-error`**](9-error/#files) &nbsp;&mdash;&nbsp; customize all error
  responses in one place.
- [**`a-log`**](a-log/#files) &nbsp;&mdash;&nbsp; writing messages to Dream's
  log.
- [**`b-session`**](b-session/#files) &nbsp;&mdash;&nbsp; associates state with
  client sessions.
- [**`c-cookie`**](c-cookie/#files) &nbsp;&mdash;&nbsp; sets custom cookies.
- [**`d-form`**](d-form#files) &nbsp;&mdash;&nbsp; reads forms with CSRF
  prevention.
- [**`e-json`**](e-json#files) &nbsp;&mdash;&nbsp; sends and receives JSON
  securely.
- [**`f-static`**](f-static#files) &nbsp;&mdash;&nbsp; serves static files from
  a local directory.
- [**`g-upload`**](g-upload#files) &nbsp;&mdash;&nbsp; receives file uploads.
- [**`h-sql`**](h-sql#files) &nbsp;&mdash;&nbsp; queries an SQL database.
- [**`i-graphql`**](i-graphql#files) &nbsp;&mdash;&nbsp; serves a GraphQL
  schema and GraphiQL.
- [**`j-stream`**](j-stream#files) &nbsp;&mdash;&nbsp; streams request and
  response bodies.
- [**`k-websocket`**](k-websocket#files) &nbsp;&mdash;&nbsp; opens a WebSocket
  between client and server.
- [**`l-https`**](l-https#files) &nbsp;&mdash;&nbsp; enables HTTPS and HTTP/2
  upgrades.

That's it for the tutorial!

<br>

# Reason

There are several examples showing Dream with Reason syntax.

- [**`r-hello`**](r-hello#files) &nbsp;&mdash;&nbsp; the simplest Dream server.
- [**`r-template`**](r-template#files) &nbsp;&mdash;&nbsp; renders HTML
  templates and protects against XSS.
- [**`r-template-stream`**](r-template-stream#files) &nbsp;&mdash;&nbsp; streams
  templates as response bodies.
- [**`r-fullstack-melange`**](r-fullstack-melange#files) &nbsp;&mdash;&nbsp;
  server *and* client written in Reason!

<br>

# Examples

The rest of the examples cover additional topics in a more-standalone fashion.
The goal of the examples is to (eventually) cover the great majority of
real-world HTTP usage, so that they make up a good survey. Please open an issue
if something is missing!

<br>

- [**`w-fullstack-rescript`**](w-fullstack-rescript#files) &nbsp;&mdash;&nbsp;
  shares OCaml code between server and client.
- [**`w-long-polling`**](w-long-polling#files) &nbsp;&mdash;&nbsp; old form of
  asynchronous communication without WebSockets.
- [**`w-query`**](w-query#files) &nbsp;&mdash;&nbsp; reads URL query parameters.
- [**`w-server-sent-events`**](w-server-sent-events#files) &nbsp;&mdash;&nbsp;
  [`EventSource`](https://developer.mozilla.org/en-US/docs/Web/API/EventSource),
  an older alternative to WebSockets.
- [**`w-template-stream`**](w-template-stream#files) &nbsp;&mdash;&nbsp; sends
  templates asynchronously, one chunk at a time.

<br>
<br>

# Roadmap

These examples will be trickled in during the alpha releases.

Ideas:

- `w-auto-reload`
- [**`w-fullstack-rescript`**](w-fullstack-rescript#files) &nbsp;&mdash;&nbsp;
  done.
- `w-index-html`
- `w-one-binary`
- `w-ppx-deriving`
- `w-react-spa`
- `w-subcommand`
- `w-template-directory`
- `w-tyxml` &nbsp;&mdash;&nbsp; for
  [TyXML](https://github.com/ocsigen/tyxml/) templates.

Basics:

- `w-content-negotiation`
- [**`w-query`**](w-query#files) &nbsp;&mdash;&nbsp; done.
- `w-scope` &nbsp;&mdash;&nbsp; for
  [`Dream.scope`](https://aantron.github.io/dream/#val-scope).
- `w-subsite` &nbsp;&mdash;&nbsp; for
  [`*` routes](https://aantron.github.io/dream/#val-router).
- `w-testing` &nbsp;&mdash;&nbsp; for
  [*Testing*](https://aantron.github.io/dream/#testing).
- `w-site-prefix` &nbsp;&mdash;&nbsp; a Web app running not at `/`.

Security:

- `w-auth`
- `w-cookie-session` &nbsp;&mdash;&nbsp; for
  [`Dream.cookie_sessions`](https://aantron.github.io/dream/#val-cookie_sessions).
- `w-cors`
- `w-sql-session` &nbsp;&mdash;&nbsp; for
  [`Dream.sql_sessions`](https://aantron.github.io/dream/#val-sql_sessions).
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
- `w-graphql-subscriptions`
- `w-https-redirect`
- [**`w-long-polling`**](w-long-polling#files) &nbsp;&mdash;&nbsp; done.
- `w-postgres-docker`
- [**`w-server-sent-events`**](w-server-sent-events#files) &nbsp;&mdash;&nbsp;
  done.
- `w-sql-stream`
- [**`w-template-stream`**](w-template-stream#files) &nbsp;&mdash;&nbsp; done.
- `w-websocket-stream`


<!-- TODO Note that each example is fully self-contained... But also show an
     example that uses crunch to be truly 1-file even with static content. -->
<!-- TODO Show self-contained example with ppx_blob. -->
<!-- TODO HTTP2 example is unnecessary - HTTP2 is transparent. -->
<!-- TODO Insert sessions example before cookies example. It should be 7,
     actually, before form, because form is based on CSRF which is based on
     sessions. For now, it is in h-login. -->
<!-- TODO Also need an example that demonstrates typed sessions and how trivial
     they are. -->
<!-- TODO Need an upload example. Make a hex-dumping server or something. -->
<!-- TODO Lwt/promise example. -->
<!-- TODO Recommend empty responses -->
