Dream's first several examples make up a **tutorial**. Each example is a
complete project with a helpful `README`, and plenty of links to next steps and
documentation. You can begin at [**`1-hello`**](1-hello#files), or look in the
list below and jump to whatever interests you!

- [**`1-hello`**](1-hello#files) &nbsp;&mdash;&nbsp; the simplest Dream server
  responds to every request with the same friendly message.
- [**`2-middleware`**](2-middleware) &nbsp;&mdash;&nbsp; adds the first Dream
  middleware: the *logger*.
- [**`3-counter`**](3-counter) &nbsp;&mdash;&nbsp; our content is now slightly
  dynamic!
- [**`4-router`**](4-router) &nbsp;&mdash;&nbsp; different handlers for
  different paths.
- [**`5-echo`**](5-echo)
- [**`6-template`**](6-template) &nbsp;&mdash;&nbsp; render responses from
  templates and guard against XSS.
- [**`7-debug`**](7-debug) &nbsp;&mdash;&nbsp; centralize your error page and
  run the debugger.
- [**`8-error`**](8-error)
- [**`9-logging`**](9-logging)
- [**`a-session`**](a-session)
- [**`b-cookie`**](b-cookie)
- [**`c-form`**](c-form) &nbsp;&mdash;&nbsp; reading forms and CSRF prevention.
- [**`d-json`**](d-json)
- [**`e-static`**](e-static)
- [**`f-upload`**](f-upload)
- [**`g-sql`**](g-sql) &nbsp;&mdash;&nbsp; finally CRUD!
- [**`h-graphql`**](h-graphql)
- [**`i-streaming`**](i-streaming)
- [**`j-websocket`**](j-websocket)
- [**`k-https`**](k-https)
- [**`l-crypto`**](l-crypto)
- [**`m-locals`**](m-locals)

That's it for the tutorial!

Scroll down for *everything else*.

<br>
<br>
<br>

There are several examples of using Dream with Reason syntax:

- [**`w-reason-hello`**]()
- [**`w-reason-templates`**]()
- [**`w-reason-fullstack`**]()

<br>
<br>
<br>

The rest of the examples cover additional topics in a more-standalone fashion.
They are, however, still complete, self-contained projects in the same style.

The goal of the examples is to cover the great majority of real-world HTTP
usage, so that perusing them gives a good survey. Please open an issue if
something is missing!

<br>

Ideas:

- [**`w-auto-reload`**]()
- [**`w-fullstack`**]()
- [**`w-index-html`**]()
- [**`w-one-binary`**]()
- [**`w-ppx-deriving`**]()
- [**`w-react-spa`**]()
- [**`w-subcommand`**]()
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
