# `r-template-stream`

<br>

When a client connects to this Web app, it sends back one paragraph per second
in a response [stream](https://aantron.github.io/dream/#streaming):

```reason
let render = response => {
  %% response
  <html>
  <body>

%   let rec paragraphs = index => {
      <p><%i index %></p>
%     let%lwt () = Dream.flush(response);
%     let%lwt () = Lwt_unix.sleep(1.);
%     paragraphs(index + 1);
%   };
%   let%lwt () = paragraphs(0);

  </body>
  </html>
};

let () =
  Dream.run
  @@ Dream.logger
  @@ _ => Dream.stream(~headers=[("Content-Type", Dream.text_html)], render);
```

<pre><code><b>$ cd example/r-template-stream</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Visit [http://localhost:8080](http://localhost:8080)
[[playground](http://dream.as/r-template-stream)] to see it in action.

The important differences with regular usage of templates are:

- We create the response with
  [`Dream.stream`](https://aantron.github.io/dream/#val-stream), which is a
  convenience wrapper around some [lower-level
  functions](https://aantron.github.io/dream/#val-with_stream) that would
  prepare a response for streaming.
- We use the opening line `%% response` to tell the templater that we don't want
  to build a string, but to stream the template to a response in scope under the
  name `response`.
- We use the promise library [Lwt](https://github.com/ocsigen/lwt) inside the
  template for asynchronous control flow. See example
  [**`5-promise`**](../5-promise#files) for an introduction to Lwt.

The call to [`Dream.flush`](https://aantron.github.io/dream/#val-flush) isn't
necessary in most real-world cases &mdash; Dream's HTTP layer automatically
schedules the writing of data. However, this example is trying to appear
interactive, so we force writing of all output after generating each `<p>` tag.

<br>

**See also:**

- [**`r-template`**](../r-template#files) for the simpler way to do templates,
  building up entire bodies as strings.
- [**`7-template`**](../7-template#security) section *Security* for XSS
  prevention considerations.
- [**`w-template-stream`**](../w-template-stream#files) is the OCaml version of
  this example.

<br>

[Up to the example index](../#reason)

<!-- TODO OWASP link; injection general link. -->
<!-- TODO Link to template syntax reference. -->
