<h1 align="center">Dream</h1>

<p align="center">
Easy-to-use, feature-complete Web framework without any boilerplate.
</p>

<br>

<p align="center">
<img src="https://raw.githubusercontent.com/aantron/dream/master/docs/asset/sample.png"></img>
</p>

<br>
<br>

*Note: the project is in a pre-alpha state; currently writing examples.*

Dream is [**one flat module**][api-main] in **one package**, offering:

- Easy **HTTPS** and **HTTP/2** support &mdash; Dream runs without a proxy.
- [**WebSockets**][websocket] and [**GraphQL**][graphql] for your modern Web
  apps.
- [**HTML templates**][templates] with embedded OCaml or
  [Reason][reason-templates] &mdash; use existing skills!
- Composable [**middleware**][middleware] and [**routes**][routing].
- Easy-to-use functions for [**secure cookies**][cookies] and
  [**CSRF-safe forms**][forms].
- [**Sessions**][sessions] with pluggable storage [back ends][back-ends].
- Unified, internationalization-friendly [**error handling**][errors].
- [**Cryptography**][crypto] helpers, key rotation, and a chosen cipher.
- A neat [**logger**][logging], and attention to configuring the OCaml runtime
  nicely.

<br>

Every part of the API is arranged to be easy to understand, use, and remember.
Dream sticks to base OCaml types like `string` and `list`, introducing only a
few [types][types] of its own &mdash; and some of those are just abbreviations
for bare functions!

The neat interface is not a limitation. Everything is still configurable by a
large number of optional arguments. Where necessary, Dream exposes the
lower-level machinery that it is composed from. For example, the default body
and WebSocket readers return strings, but you can also do [zero-copy
streaming][streaming].

You can even run Dream as a [quite bare abstraction][raw] over its [underlying
set of HTTP libraries][vendor], where it acts only as minimal glue code between
their slightly different interfaces, and takes care of horridness like
[ALPN][alpn].

[websocket]: https://aantron.github.io/dream/#websockets
[graphql]: https://aantron.github.io/dream/#graphql
[templates]: https://github.com/aantron/dream/tree/master/example/7-template#files
[reason-templates]: https://github.com/aantron/dream/tree/master/example/r-template#files
[middleware]: https://github.com/aantron/dream/tree/master/example/4-counter#files
[routing]: https://aantron.github.io/dream/#routing
[cookies]: https://github.com/aantron/dream/tree/master/example/c-cookie#files
[forms]: https://github.com/aantron/dream/tree/master/example/d-form#files
[sessions]: https://github.com/aantron/dream/tree/master/example/b-session#files
[back-ends]: https://aantron.github.io/dream/#back-ends
[errors]: https://github.com/aantron/dream/tree/master/example/9-error#files
[crypto]: https://aantron.github.io/dream/#cryptography
[logging]: https://aantron.github.io/dream/#logging
[types]: https://aantron.github.io/dream/#types
[streaming]: https://aantron.github.io/dream/#streaming
[raw]: https://aantron.github.io/dream/#builtin
[alpn]: https://en.wikipedia.org/wiki/Application-Layer_Protocol_Negotiation

<br>

## Documentation

- Dream has several dozen [**Examples**][examples], each of which is a complete
  project in the public domain. *Note: only about two dozen actually written
  ATM.*

- The first examples make up a [**Tutorial**][examples]. Visit to see the full
  list and start wherever you  like, or begin at [**`1-hello`**][1-hello], the
  Dream version of *Hello, world!*

- Several of the examples and tutorials are available in
  [**Reason syntax**][reason-examples], with more to come over time!

- See the [**API documentation**][api-main].

[examples]: https://github.com/aantron/dream/tree/master/example#readme
[1-hello]: https://github.com/aantron/dream/tree/master/example/1-hello#files
[reason-examples]: https://github.com/aantron/dream/tree/master/example#reason

<!-- TODO LATER CI badges, opam link badge, npm badge. -->
<!-- TODO Clone instructions should include --recursive. -->

<br>

## Getting started

*TODO opam release, esy instructions, quick-start script.*

```
opam install dream
```

[api-main]: https://aantron.github.io/dream/#types

<br>

## Contributing

Dream uses several [submodules][vendor], so be sure to clone with

```
git clone https://github.com/aantron/dream.git --recursive
```

<br>

## Acknowledgements

Dream is based on work by the authors and contributors of its many
[dependencies][opamfile] and their transitive dependencies. There are, however,
several influences that cannot be discovered directly:

- Templates are inspired by [**ECaml**][ecaml] from [Alexander Markov][komar]
  and [**Embedded OCaml Templates**][eot] from [Emile Trotignon][trotignon].
- Dream's handlers and middlewares are simplified from [**Opium**][opium] by
  [Rudi Grinberg][rgrinberg] and contributors.
- The lower-level HTTP and WebSocket servers are [vendored][vendor] copies of
  [Antonio Nuno Monteiro][anmonteiro]'s forks and original works, with credit
  also due to their contributors, and [Spiros Eliopoulos][seliopou] in
  particular, as the original author of two of the projects.
- The API docs are instantiated by [**Soupault**][soupault] from
  [Daniil Baturin][dmbaturin].
- The name was inspired by [**Morph**][morph] from [Ulrik Strid][ulrikstrid],
  which was itself partially inspired by [Opium][opium].
- [Raphael Rafatpanah][persianturtle] and [El-Hassan Wanas][foocraft] provided
  important early feedback.

[ecaml]: http://komar.in/en/code/ecaml
[komar]: https://github.com/apsheronets
[eot]: https://github.com/EmileTrotignon/embedded_ocaml_templates
[trotignon]: https://github.com/EmileTrotignon
[opamfile]: https://github.com/aantron/dream/blob/master/dream.opam
[opium]: https://github.com/rgrinberg/opium
[vendor]: https://github.com/aantron/dream/tree/master/src/vendor
[rgrinberg]: https://github.com/rgrinberg
[anmonteiro]: https://github.com/anmonteiro
[soupault]: https://github.com/dmbaturin/soupault
[dmbaturin]: https://github.com/dmbaturin
[morph]: https://github.com/reason-native-web/morph
[ulrikstrid]: https://github.com/ulrikstrid
[seliopou]: https://github.com/seliopou
[persianturtle]: https://github.com/persianturtle
[foocraft]: https://github.com/foocraft

<br>

## Roadmap

1.0.0~alpha1:

- [ ] Finish more of the examples, cross-link everything.
- [ ] Correct the cipher rotation envelope scheme.
- [ ] Quick start script.

Then:

- [ ] Optimizations: router, logger, microparsers (form data, etc.), fully
      zero-allocation streaming.
- [ ] WebSocket and stream backpressure.
- [ ] HTTP3/QUIC.



<!-- Example install: how to install opam, how to install deps, add to Makefile
     targets. -->
<!-- hyperlink localhost in examples -->
<!-- ld: /opt/local/libn ot found on mac -->
<!-- Path parsing of # $ in targets -->
<!-- update code in exampels -->
<!-- Reason example -->
<!-- Reason mode in docs -->
<!-- examples: are exceptions isolated? yes -->
<!-- Ctrl+C needed to get out of error page caues of no content-legnth -->
<!-- esy workflow -->
