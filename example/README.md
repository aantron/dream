# Tutorial

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
- [**`6-template`**](6-template/#files) &nbsp;&mdash;&nbsp; render responses
  from templates and guard against XSS.
- [**`7-debug`**](7-debug) &nbsp;&mdash;&nbsp; centralize your error page and
  run the debugger.
- [**`8-error-page`**](8-error-page)
- [**`9-logging`**](9-logging)
- [**`a-promise`**](a-promise)
- [**`b-session`**](a-session)
- [**`c-cookie`**](b-cookie)
- [**`d-form`**](c-form) &nbsp;&mdash;&nbsp; reading forms and CSRF prevention.
- [**`e-json`**](d-json)
- [**`f-static`**](e-static)
- [**`g-upload`**](f-upload)
- [**`h-sql`**](g-sql) &nbsp;&mdash;&nbsp; finally CRUD!
- [**`i-graphql`**](h-graphql)
- [**`j-streaming`**](i-streaming)
- [**`k-websocket`**](j-websocket)
- [**`l-https`**](k-https)
- [**`m-crypto`**](l-crypto)
- [**`n-locals`**](m-locals)

That's it for the tutorial!

<br>

# Reason

There are several examples showing Dream with Reason syntax. They also use esy
`package.json`.

- [**`w-reason-hello`**]()
- [**`w-reason-template`**]()
- [**`w-reason-fullstack`**]()

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
- [**`w-sql-streaming`**]()
- [**`w-template-streaming`**]()
- [**`w-websocket-streaming`**]()

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
<!-- TODO Get rid of the Makefiles. -->
<!-- TODO Lwt/promise example. -->
