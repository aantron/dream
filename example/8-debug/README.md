# `8-debug`

<br>

Dream has a built-in error handler for showing debug information. You can enable
it by passing it to `Dream.run`:

```ocaml
let () =
  Dream.run ~error_handler:Dream.debug_error_handler
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/bad"
      (fun _ ->
        Dream.empty `Bad_Request);

    Dream.get "/fail"
      (fun _ ->
        raise (Failure "The Web app failed!"));

  ]
```

<pre><code><b>$ cd example/8-debug</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

The rest of the app just adds two routes for triggering two kinds of
failures that the debugger will detail. Visit
[http://localhost:8080/bad](http://localhost:8080/bad)
[[playground](http://dream.as/8-debug/bad)] to trigger a `400 Bad Request`
response, and [http://localhost:8080/fail](http://localhost:8080/fail)
[[playground](http://dream.as/8-debug/fail)] to trigger an exception. The
debugger will show reports like this:

```
Failure("The Web app failed!")
Raised at Stdlib__map.Make.find in file "map.ml", line 137, characters 10-25
Called from Logs.Tag.find in file "src/logs.ml", line 154, characters 14-32

From: Application
Blame: Server
Severity: Error

Client: 127.0.0.1:64687

GET /fail HTTP/1.1
Host: localhost:8080
Connection: keep-alive
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
Sec-GPC: 1
Sec-Fetch-Site: none
Sec-Fetch-Mode: navigate
Sec-Fetch-User: ?1
Sec-Fetch-Dest: document
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.9,ru-RU;q=0.8,ru;q=0.7

dream.client: 127.0.0.1:64687
dream.tls: false
dream.request_id: 3
dream.params:
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
- any other request variables.

<!-- TODO Link to the tutorial example on variables and also mention that they
     are advanced and usually internal. -->

<br>

The debugger is disabled by default to avoid leaking information by accident in
a production environment. Whether the debugger is enabled or disabled, Dream
still writes error messages to the server-side log. The debugger is only about
also sending error details to the client as *reponses*, which can be easier to
work with in development.

<br>

You can have Dream show a custom error page with any information or graphics
that you like &mdash; we will do this in the [very next
example](../9-error#files)!

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
