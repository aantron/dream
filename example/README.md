Each subdirectory here is a complete project. If you like one, you can copy it
out and use it to get started! You can run each example from its directory by
typing `make`.

<br/>

- [**`1-hello`**](1-hello) &nbsp;&mdash;&nbsp; the simplest Dream server;
  responds to every request with the same friendly message.
- [**`2-middleware`**](2-middleware) &nbsp;&mdash;&nbsp; adds the first Dream
  middleware: the *logger*.
- [**`3-counter`**](3-counter) &nbsp;&mdash;&nbsp; our content is now slightly
  dynamic!
- [**`4-router`**](4-router) &nbsp;&mdash;&nbsp; different handlers for
  different paths.
- [**`5-catch`**](5-catch) &nbsp;&mdash;&nbsp; centralize your error page and
  run the debugger.
- [**`6-template`**](6-template) &nbsp;&mdash;&nbsp; render responses from
  templates and guard against XSS.
- [**`7-form`**](7-form) &nbsp;&mdash;&nbsp; reading forms and CSRF prevention.
- [**`8-sql`**](8-sql) &nbsp;&mdash;&nbsp; finally CRUD!
- [**`9-cookie`**](9-cookie)
- [**`a-query`**](10-query)
- [**`b-static`**](11-static)
- [**`c-streaming`**](12-streaming)
- [**`d-locals`**]()
- [**`e-ajax`**]()
- [**`f-websocket`**]()
- [**`g-ssl`**]()
- [**`h-login`**]()
- [**`i-i18n`**]()
- [**`j-graphql`**]()
- [**`k-http2`**]()
- [**`l-metadata`**]()
- [**`m-migration`**]()
- [**`n-testing`**]()

<!-- TODO Note that each example is fully self-contained... But also show an
     example that uses crunch to be truly 1-file even with static content. -->
<!-- TODO Show self-contained example with ppx_blob. -->
<!-- TODO HTTP2 example is unnecessary - HTTP2 is transparent. -->
<!-- TODO Insert sessions example before cookies example. It should be 7,
     actually, before form, because form is based on CSRF which is based on
     sessions. For now, it is in h-login. -->
