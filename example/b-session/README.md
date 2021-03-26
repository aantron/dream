# `b-session`

<br>

Introducing sessions is straightforward:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sessions_in_memory
  @@ fun request ->
    match Dream.session "user" request with
    | None ->
      let%lwt () = Dream.invalidate_session request in
      let%lwt () = Dream.set_session "user" "anastasios" request in
      Dream.respond "You weren't logged in; but now you are!"

    | Some username ->
      Printf.ksprintf
        Dream.respond "Welcome back, %s!" (Dream.html_escape username)
```

<pre><code><b>$ dune exec --root . ./session.exe</b></code></pre>

<br>

The first time you access the app, it “logs you in” by saving you user name in a
session. The session manager, `Dream.sessions_in_memory`, a middleware, adds a
session ID cookie to the response. The next time you access the app, the
session is looked up again by ID, and the app recognizes you as logged in!

<br>

<!-- TODO: the other built-in session managers. -->

In fact, all of this is a special case of a very flexible session mechanism in
Dream, which has been configured with tidy defaults. Dream has built-in session
managers that store session data either...

- server-side, **in memory**, and send a session ID, so you can get started
  prototyping without configuring a database or encryption keys;
- server-side, in a **database** &mdash; same as above, but use a database to
  survive server restarts; or
- server-side, in a **file** &mdash; also survives restarts, good for
  prototyping; or
- client-side, in **encrypted cookies** sent to the client.

Client-side sessions actually work out of the box &mdash; just replace
`Dream.sessions_in_memory` with `Dream.client_side_sessions`. However, if you
don't also pass `~secret` to `Dream.run`, Dream generates a random encryption
key each time it starts, so the useful lifetime of these sessions is the same
as for in-memory sessions anyway &mdash; the lifetime of the web app process.

<!-- TODO Link to recommendations. -->

<br>

The default sessions provided by Dream contain string-to-string maps (dicts). In
the example, we created

```
{
  "user": "anastasios"
}
```

This is good enough for many apps. However, you can set up Dream sessions to
store values of any OCaml type. **DOCS TODO; link to the advanced examples**

<br>

Dream's built-in session managers all create *pre-sessions*. That is, all visits
to handlers under session middleware get assigned a session. If a visitor is not
logged in, they still get a new session &mdash; this is a *pre-session*.
Pre-sessions help generate secure forms for visitors who are not logged in.

TODO Rewrite this paragraph, it is garbage, it's more of a reminder to write a
real one.

<!-- TODO Link to typed session docs. -->

<br>

## Security

- TODO Fixation
- TODO Key exhaustion.

<br>

**Next steps:**

- Sessions already use cookies internally, but in
  [**`c-cookie`**](../c-cookie/#files) we set cookies for our own purposes!
- [**`d-form`**](../d-form/#files) builds secure forms on top of sessions.

<br>

[Up to the tutorial index](../#readme)
