<h1 align="center">Dream</h1>

<p align="center">
Easy-to-use, feature-complete Web framework without boilerplate.
</p>

<br>

<p align="center">
<img src="https://raw.githubusercontent.com/aantron/dream/master/docs/asset/sample.png"></img>
</p>

<br>

<pre align="center"><b>bash -c "$(curl -fsSL https://raw.githubusercontent.com/aantron/dream/master/example/quickstart.sh)"</b></pre>

<br>
<br>

Dream is **one flat module** in **one package**, documented on
[**one page**][api-main], but with [**many examples**][tutorial]. It offers:

- [**WebSockets**][websocket] and [**GraphQL**][graphql] for your modern Web
  apps.
- [**HTML templates**][templates] with embedded OCaml or
  [Reason][reason-templates] &mdash; use existing skills!
- [**Sessions**][sessions] with pluggable storage [back ends][back-ends].
- Easy [**HTTPS** and **HTTP/2** support][https] &mdash; Dream runs without a
  proxy.
- Helpers for [**secure cookies**][cookies] and
  [**CSRF-safe forms**][forms].
- **Full-stack ML** with clients by [**Melange**][melange],
  [**ReScript**][rescript], or [**js_of_ocaml**][jsoo].

<br>

...all without sacrificing ease of use &mdash; Dream has:

- A simple programming model &mdash; Web apps are [**just functions**][handler]!
- Composable [**middleware**][middleware] and [**routes**][routing].
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
lower-level machinery that it is composed from. For example, the basic body and
WebSocket readers return strings, but you can also do [zero-copy
streaming][streaming].

You can even run Dream as a [quite bare abstraction][raw] over its [underlying
set of HTTP libraries][vendor], where it acts only as minimal glue code between
their slightly different interfaces, and takes care of horridness like
[ALPN][alpn].

And, even though Dream is presented as one package for ordinary usage, it is
internally factored into [several sub-libraries][libs], according to the
different dependencies of each, for fast porting to different environments.

[https]: https://github.com/aantron/dream/tree/master/example/l-https#files
[websocket]: https://github.com/aantron/dream/tree/master/example/k-websocket#files
[graphql]: https://github.com/aantron/dream/tree/master/example/w-graphql-subscription#files
[templates]: https://github.com/aantron/dream/tree/master/example/7-template#files
[reason-templates]: https://github.com/aantron/dream/tree/master/example/r-template#files
[middleware]: https://github.com/aantron/dream/tree/master/example/2-middleware#files
[handler]: https://aantron.github.io/dream/#type-handler
[routing]: https://github.com/aantron/dream/tree/master/example/3-router#files
[cookies]: https://aantron.github.io/dream/#cookies
[forms]: https://aantron.github.io/dream/#forms
[sessions]: https://github.com/aantron/dream/tree/master/example/b-session#files
[back-ends]: https://aantron.github.io/dream/#back-ends
[errors]: https://github.com/aantron/dream/tree/master/example/9-error#files
[crypto]: https://aantron.github.io/dream/#cryptography
[logging]: https://github.com/aantron/dream/tree/master/example/2-middleware#files
[melange]: https://github.com/aantron/dream/tree/master/example/r-fullstack-melange#files
[rescript]: https://github.com/aantron/dream/tree/master/example/w-fullstack-rescript#files
[jsoo]: https://github.com/aantron/dream/tree/master/example/w-fullstack-jsoo#files
[types]: https://aantron.github.io/dream/#types
[streaming]: https://aantron.github.io/dream/#streaming
[raw]: https://aantron.github.io/dream/#builtin
[alpn]: https://en.wikipedia.org/wiki/Application-Layer_Protocol_Negotiation
[libs]: https://github.com/aantron/dream/tree/master/src

<br>

## Quick start

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aantron/dream/master/example/quickstart.sh)"
```

This [script][quickstart.sh] does a sandboxed build of one of the first
[tutorials][tutorial], [**`2-middleware`**][2-middleware], which you can then
edit.

It's mostly the same as:

```
git clone https://github.com/aantron/dream.git
cd dream/example/2-middleware
npm install esy && npx esy
npx esy start
```

Knowing that, you can start from any other [example][tutorial]. All of them
include their own build commands. You can copy them out to start your own
project directory. Especially consider starting with the
[full-stack examples][fullstack], which build both a Dream server and a
JavaScript client.

### opam

```
opam install dream
```

After that, go to one of the examples, such as [**`1-hello`**][1-hello], and
build it:

```
cd example/1-hello
dune exec --root . ./hello.exe
```

[esy-example]: https://github.com/aantron/dream/tree/master/example/w-esy#files
[quickstart.sh]: https://github.com/aantron/dream/blob/master/example/quickstart.sh
[esy]: https://esy.sh/
[2-middleware]: https://github.com/aantron/dream/tree/master/example/2-middleware#files

<br>

## Documentation

- [**Tutorial**][tutorial] &mdash; Threads together the first several examples
  of Dream, touching all the basic topics, including security. See the full list
  and start wherever you like, or begin at [**`1-hello`**][1-hello], the Dream
  version of *Hello, world!*
- [**Reason syntax**][reason-examples] &mdash; Several of the examples are
  written in Reason. See [**`r-hello`**][r-hello].
- [**Full-stack**][fullstack] &mdash; See skeleton projects
  [**`r-fullstack-melange`**][melange], [**`w-fullstack-rescript`**][rescript],
  and [**`w-fullstack-jsoo`**][jsoo].
- [**Deploying**][deploying] &mdash; Quick start instructions for
  small-to-medium deployments.
- [**Examples**][examples] &mdash; These cover various HTTP scenarios.
- [**API reference**][api-main]

[tutorial]: https://github.com/aantron/dream/tree/master/example#readme
[examples]: https://github.com/aantron/dream/tree/master/example#examples
[1-hello]: https://github.com/aantron/dream/tree/master/example/1-hello#files
[r-hello]: https://github.com/aantron/dream/tree/master/example/r-hello#files
[reason-examples]: https://github.com/aantron/dream/tree/master/example#reason
[deploying]: https://github.com/aantron/dream/tree/master/example#deploying
[api-main]: https://aantron.github.io/dream/#types
[fullstack]: https://github.com/aantron/dream/tree/master/example#full-stack

<!-- TODO LATER CI badges, opam link badge, npm badge. -->

<br>

## Contact

Apart from the [issues](https://github.com/aantron/dream/issues), good places
to discuss Dream are...

- The [OCaml](https://discord.gg/DyhPFYGr) and/or
  [Reason](https://discord.gg/YCTDuzbg) Discord servers.
- The [OCaml Discuss forum](https://discuss.ocaml.org/).

Highlight `@antron` to poke @aantron specifically.

<br>

## Contributing

All kinds of contributions are welcome, including examples, links to blogs,
related libraries, and, of course, PRs! See [CONTRIBUTING.md][contributing.md].

As an immediate note, if you'd like to clone the repo, be sure to use

```
git clone https://github.com/aantron/dream.git --recursive
```

The `--recursive` flag is necessary because Dream uses several git
[submodules][vendor].

[contributing.md]: https://github.com/aantron/dream/blob/master/docs/CONTRIBUTING.md

<br>

## Acknowledgements

Dream is based on work by the authors and contributors of its [**many
dependencies**][opamfile] and their transitive dependencies. There are, however,
several influences that cannot be discovered directly:

- Templates are inspired by [**ECaml**][ecaml] from [Alexander Markov][komar]
  and [**Embedded OCaml Templates**][eot] from [Emile Trotignon][trotignon].
- Dream's handler and middleware types are simplified from [**Opium**][opium] by
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

- [x] GraphQL subscriptions.
- [ ] Optimizations: router, logger, microparsers (form data, etc.), fully
      zero-allocation streaming.
- [ ] WebSocket and stream backpressure.
- [ ] HTTP3/QUIC.
- [ ] Review JSON.
- [ ] Review SQL prepared statements.
- [ ] Switch to AEAD_AES_256_GCM_SIV for the cipher.
- [ ] WebSocket streaming (frames).
- [ ] Factor out internal sub-libraries to port Dream to MirageOS, etc.
- [ ] Token rotation-based session management.
- [ ] Lots of optionals for decoupling defaults, e.g. forms without CSRF
      checking, SQL sessions with a different database.
- [x] Bundle GraphiQL into a single HTML file that does not access any external
      CDN.
- [ ] Maybe a logo.
- [ ] i18n helper, URL templates.
- [ ] Auth library.
- [ ] Maybe REST helpers.
- [ ] Maybe Async support.
- [ ] Multicore.
- [ ] Effects.
- [ ] Proxy headers support.
- [ ] Introspection.
- [ ] Dependency reduction, especially system dependencies.
- [ ] And *lots*, *lots* more.



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
