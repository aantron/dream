# Tutorial

<!-- Link to tutorial getting started instructions. -->

Dream's first several examples make up a **tutorial**. Each example is a
complete project with a helpful `README`, and plenty of links to next steps and
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
- [**`5-echo`**](5-echo/#files) &nbsp;&mdash;&nbsp; reads request bodies.
- [**`6-template`**](6-template/#files) &nbsp;&mdash;&nbsp; renders responses
  from inline HTML templates and guards against XSS.
- [**`7-debug`**](7-debug/#files) &nbsp;&mdash;&nbsp; includes detailed
  information
  about errors in responses.
- [**`8-error`**](8-error/#files) &nbsp;&mdash;&nbsp; customize all error
  responses in one place.
- [**`9-log`**](9-log/#files) &nbsp;&mdash;&nbsp; writing messages to Dream's
  log.
- [**`a-promise`**](a-promise/#files) &nbsp;&mdash;&nbsp; introduces Lwt, the
  promise library used by Dream.
- [**`b-session`**](b-session/#files) &nbsp;&mdash;&nbsp; associates state with
  client sessions.
- [**`c-cookie`**](c-cookie/#files) &nbsp;&mdash;&nbsp; sets custom cookies.
- [**`d-form`**](d-form) &nbsp;&mdash;&nbsp; reading forms and CSRF prevention.
- [**`e-json`**](e-json)
- [**`f-static`**](f-static)
- [**`g-upload`**](g-upload)
- [**`h-sql`**](h-sql) &nbsp;&mdash;&nbsp; finally CRUD!
- [**`i-graphql`**](i-graphql)
- [**`j-stream`**](j-stream)
- [**`k-websocket`**](k-websocket)
- [**`k-https`**](k-https)

That's it for the tutorial!

<br>

# Reason

There are several examples showing Dream with Reason syntax.

- [**`r-hello`**]()
- [**`r-template`**]()
- [**`r-template-stream`**]()
- [**`r-fullstack`**]()

<br>

# Extras

The rest of the examples cover additional topics in a more-standalone fashion.
The goal of the examples is to cover the great majority of real-world HTTP
usage, so that they make up a good survey. Please open an issue if something is
missing!

<br>

Ideas:

- [**`w-auto-reload`**]()
- [**`w-fullstack`**]()
- [**`w-index-html`**]()
- [**`w-one-binary`**]()
- [**`w-ppx-deriving`**]()
- [**`w-react-spa`**]()
- [**`w-subcommand`**]()
- [**`w-template-directory`**]()
- [**`w-tyxml`**]()

Basics:

- [**`w-content-negotiation`**]()
- [**`w-query`**]()
- [**`w-scope`**]()
- [**`w-subsite`**]()
- [**`w-testing`**]()

Security:

- [**`w-auth`**]()
- [**`w-client-side-session`**]()
- [**`w-cors`**]()
- [**`w-database-session`**]()
- [**`w-file-session`**]()
- [**`w-form-expired`**]()
- [**`w-json-csrf`**]()
- [**`w-jwt`**]()
- [**`w-key-rotation`**]()
- [**`w-upload-csrf`**]()

Techniques:

- [**`w-etag`**]()
- [**`w-graphql-sql`**]()
- [**`w-graphql-subscriptions`**]()
- [**`w-https-redirect`**]()
- [**`w-long-polling`**]()
- [**`w-postgres-docker`**]()
- [**`w-server-sent-events`**]()
- [**`w-sql-stream`**]()
- [**`w-template-stream`**]()
- [**`w-websocket-stream`**]()

Advanced customization:

- [**`w-globals`**]()
- [**`w-typed-session`**]()


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
