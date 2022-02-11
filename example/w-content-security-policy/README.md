# `w-content-security-policy`

<br>

The [`Content-Security-Policy`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy)
(CSP) header is used to control where your Web pages can be embedded, and what
content they can be made to load. This example uses the CSP
[`frame-ancestors`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/frame-ancestors)
directive to prevent a page from being loaded inside a frame, which can help
prevent
[clickjacking](https://cheatsheetseries.owasp.org/cheatsheets/Clickjacking_Defense_Cheat_Sheet.html).
In addition, it tells the browser to send CSP violation reports back to the
server:

```ocaml
let home =
  <html>
  <body>
    <iframe src="/nested"></iframe>
  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.html home);

    Dream.get "/nested" (fun _ ->
      Dream.html
        ~headers:["Content-Security-Policy",
          "frame-ancestors 'none'; " ^
          "report-uri /violation"]
        "You should not be able to see this inside a frame!");

    Dream.post "/violation" (fun request ->
      let%lwt report = Dream.body request in
      Dream.error (fun log -> log "%s" report);
      Dream.empty `OK);

  ]
```

<pre><code><b>$ cd example/w-content-security-policy</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Visit [http://localhost:8080](http://localhost:8080)
[[playground](http://dream.as/w-content-security-policy)], and your browser
should refuse to show `/nested` inside the frame on the home page. In addition,
the server log will show something like

```
09.06.21 09:54:35.971                 ERROR REQ 3 {
  "csp-report": {
    "document-uri": "http://localhost:8080/",
    "referrer": "",
    "violated-directive": "frame-ancestors",
    "effective-directive": "frame-ancestors",
    "original-policy": "frame-ancestors 'none'; report-uri /violation",
    "disposition": "enforce",
    "blocked-uri": "http://localhost:8080/",
    "status-code": 200,
    "script-sample": ""
  }
}
```

<br>

You can use CSP to limit which resources can be loaded by the pages you serve,
forbid execution of JavaScript `eval`, and so on. You may want to apply CSP by
writing a wrapper around
[`Dream.html`](https://aantron.github.io/dream/#val-html), or in a middleware.
Note that static file loaders such as
[`Dream.from_filesystem`](https://aantron.github.io/dream/#val-from_filesystem)
can also serve HTML pages, so if you choose not to use a middleware and have
static HTML pages, be sure to write a custom static loader as well.

Dream does not offer a default CSP, because it will inevitably interfere with
development, depending on what each Web app is using. Also, it is possible not
to use CSP at all &mdash; CSP is only a defense-in-depth technique. However, it
is highly recommended to eventually look through the CSP directives as your Web
app develops. When enabling CSP, also consider
[`Strict-Transport-Security`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security).

<br>

**See:**

- [`Content-Security-Policy`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy) on MDN
- [`Strict-Transport-Security`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) on MDN
- OWASP [*Content Security Policy Cheat Sheet*](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
- OWASP [*Clickjacking Defense Cheat Sheet*](https://cheatsheetseries.owasp.org/cheatsheets/Clickjacking_Defense_Cheat_Sheet.html)
- OWASP [*HTTP Strict Transport Security Cheat Sheet*](https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html)

<br>

[Up to the example index](../#examples)
