# `b-session`

<br>

Adding [sessions](https://aantron.github.io/dream/#sessions) is straightforward:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ fun request ->

    match Dream.session_field request "user" with
    | None ->
      let%lwt () = Dream.invalidate_session request in
      let%lwt () = Dream.set_session_field request "user" "alice" in
      Dream.html "You weren't logged in; but now you are!"

    | Some username ->
      Printf.ksprintf
        Dream.html "Welcome back, %s!" (Dream.html_escape username)
```

<pre><code><b>$ cd example/b-session</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The first time you access the app [[playground](http://dream.as/b-session)], it
“logs you in” by saving you user name in a session. The session manager,
[`Dream.memory_sessions`](https://aantron.github.io/dream/#val-memory_sessions),
a middleware, adds a `dream.session` cookie to the response, containing the
session key. The next time you access the app, the session is looked up again
by this key, and the app recognizes you as logged in!

![Logged in](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/session.png)

<br>

The [default sessions](https://aantron.github.io/dream/#sessions) provided by
Dream contain string-to-string maps (dicts). In this example, we created

```
{
  "user": "alice"
}
```

<br>

[`Dream.memory_sessions`](https://aantron.github.io/dream/#val-memory_sessions)
stores sessions in server memory only. This is great for development, because
you don't have to worry about a database or a secret key. But it means that all
session data is lost when the server is restarted. For example, if your Web app
logs in users, server restart will log all users out.

There are two other session back ends, which are persistent:

- [`Dream.cookie_sessions`](https://aantron.github.io/dream/#val-cookie_sessions)
  stores session data in encrypted cookies. That is, session data is stored on
  clients, rather than on the server. You can replace `Dream.memory_sessions`
  with `Dream.cookie_sessions` and it will work right away. However, if you
  want to be able to decrypt sessions set by previous runs of the server, use
  the [`Dream.set_secret`](https://aantron.github.io/dream/#val-set_secret)
  middleware before `Dream.cookie_sessions`. If you don't, the server will be
  using a different random encryption key each time it starts.
- [`Dream.sql_sessions`](https://aantron.github.io/dream/#val-sql_sessions)
  stores sessions in a database. It is shown in example
  [**`h-sql`**](../h-sql#files).

<br>

All requests passing through a session middleware get assigned a session. If
they don't have a `dream.session` cookie, or the cookie is invalid, they get a
fresh, empty session, also known as a *pre-session*.

<br>

## Security

If you log in a user, grant a user or session any enhanced access rights, or
similar, be sure to replace the existing session with a new one by calling
[`Dream.invalidate_session`](https://aantron.github.io/dream/#val-invalidate_session).
This helps to mitigate
[session fixation](https://en.wikipedia.org/wiki/Session_fixation) attacks. The
new session will, again, be an empty pre-session.

It is best to use HTTPS when using sessions, to prevent session cookies from
being easily observed by third parties. See
[`Dream.run`](https://aantron.github.io/dream/#val-run) argument `~https`, and
example [**`l-https`**](../l-https#files). If you redirect from HTTP to HTTPS,
do not issue sessions for HTTP requests. If you do, don't accept them later
from HTTPS requests.

<br>
<br>

**Next steps:**

- Sessions already use cookies internally, but in
  [**`c-cookie`**](../c-cookie#files) we set cookies for our own purposes!
- [**`d-form`**](../d-form#files) builds secure forms on top of sessions.

<br>

[Up to the tutorial index](../#readme)
