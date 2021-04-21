# `8-debug`

<br>

Getting Dream to respond with more debug information is as easy as adding
`~debug:true` to [`Dream.run`](https://aantron.github.io/dream/#val-run):

```ocaml
let () =
  Dream.run ~debug:true
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/bad"
      (fun _ ->
        Dream.empty `Bad_Request);

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The Web app failed!"));

  ]
  @@ Dream.not_found
```

<pre><code><b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The rest of the app just adds two routes for triggering two kinds of
failures that the debugger will detail. Visit
[http://localhost:8080/bad](http://localhost:8080/bad) to trigger a
`400 Bad Request` response, and
[http://localhost:8080/fail](http://localhost:8080/fail) to trigger an
exception. The debugger will show reports like this:

```
(Failure "The Web app failed!")
Raised at Stdlib__string.index_rec in file "string.ml", line 115, characters 19-34
Called from Sexplib0__Sexp.Printing.index_of_newline in file "src/sexp.ml", line 113, characters 13-47

From: Application
Blame: Server
Severity: Error

Client: 127.0.0.1:61988

GET /fail HTTP/1.1
Host: localhost:8080
Connection: keep-alive
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 [...snip...]
Accept: text/html,application/xhtml+xml, [...snip...]
Sec-GPC: 1
Sec-Fetch-Site: none
Sec-Fetch-Mode: navigate
Sec-Fetch-User: ?1
Sec-Fetch-Dest: document
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US;q=0.9,en;q=0.8

dream.request_id.last_id: 2
```
<!-- Get the request id in the list. -->

As you can see, the report includes:

- the error message,
- a stack trace, if the error is an exception,
- `From:` which part of the HTTP stack reported the error (TLS, HTTP, HTTP/2,
  WebSockets, or the app),
- `Blame:` who is likely responsible for the error, the server or the client,
- `Severity:` a suggested log level for the error,
- `Client:` the client address,
- request headers,
- any request-scoped and application-scoped variables set in the request.

<!-- TODO Link to the tutorial example on variables and also mention that they
     are advanced and usually internal. -->

<br>

The debugger is disabled by default to avoid leaking information by accident in
a production environment. Whether the debugger is enabled or disabled, Dream
still writes error messages to the server-side log. The debugger is only about
also sending error details to the client as *reponses*, which can be easier to
work with in development.

<br>

Both the debugger's output and the non-debug error page are fully customizable
&mdash; we will do this in the [very next example](../9-error#files)!

<!-- TODO Fix after stack trace is fixed. -->
<!-- TODO Show the log -->
<!-- TODO API link -->

<br>

**Next steps:**

- [**`9-error`**](../9-error#files) handles all errors in one place, including
  displaying the debugger output.
- [**`a-log`**](../a-log#files) shows [log
  levels](https://aantron.github.io/dream/#type-log_level) and
  [sub-logs](https://aantron.github.io/dream/#type-sub_log).

<br>

[Up to the tutorial index](../#readme)
