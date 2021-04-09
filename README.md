<h1 align="center">Dream</h1>

<p align="center">
Easy-to-use, feature-complete Web framework without boilerplate.
</p>

<br>

<p align="center">
<img src="https://raw.githubusercontent.com/aantron/dream/master/docs/asset/sample.png"></img>
</p>

<br>
<br>

Dream is **one flat module** in **one package**, documented on
[**one page**][api-main], but with [**many examples**][tutorial]. It offers:

- Easy [**HTTPS** and **HTTP/2** support][https] &mdash; Dream runs without a
  proxy.
- [**WebSockets**][websocket] and [**GraphQL**][graphql] for your modern Web
  apps.
- [**HTML templates**][templates] with embedded OCaml or
  [Reason][reason-templates] &mdash; use existing skills!
- A simple programming model &mdash; Web apps are [**just functions**][handler]!
- Composable [**middleware**][middleware] and [**routes**][routing].
- Easy-to-use helpers for [**secure cookies**][cookies] and
  [**CSRF-safe forms**][forms].
- [**Sessions**][sessions] with pluggable storage [back ends][back-ends].
- Unified, internationalization-friendly [**error handling**][errors].
- [**Cryptography**][crypto] helpers, key rotation, and a chosen cipher.
- A neat [**logger**][logging], and attention to configuring the OCaml runtime
  nicely.
- **Full-stack ML** with [**Melange**][melange], [**ReScript**][rescript], or
  [**js_of_ocaml**][jsoo].

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
[graphql]: https://github.com/aantron/dream/tree/master/example/i-graphql#files
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

## Getting started

Dream is not yet announced or released! Before release, Dream will get a
quick-start script, and some other help for getting started quickly. However,
if you want to try Dream now, you can do:

```
git clone https://github.com/aantron/dream.git --recursive
cd dream
opam install .
```

Note: the clone *must* be `--recursive`, because Dream [vendors several
packages][vendor] as git submodules. Also, if you have `gluten`, `httpaf`, `h2`,
or `websocketaf`, or their `gluten-*`, etc., subpackages independently
installed in your switch, you may have to remove them with `opam remove` to
avoid conflicts. However, they should not be pulled into a basic build of Dream
and most programs that use it.

After that, go to one of the examples, such as [**`1-hello`**][1-hello], and
try building it:

```
cd example/1-hello
dune exec --root . ./hello.exe
```

If you prefer Reason syntax, try example [**`r-hello`**][r-hello] instead.

You should be able to copy the example out to a completely separate directory,
if you didn't use a local `_opam` switch scoped to Dream's clone directory. If
you did, you can pin Dream to your clone in a different opam switch with

```
opam pin add dream /path/to/your/clone
```

<br>

## Documentation

- [**Tutorial**][tutorial] &mdash; Threads together the first several examples
  of Dream, touching all the basic topics, including security. See the full list
  and start wherever you like, or begin at [**`1-hello`**][1-hello], the Dream
  version of *Hello, world!*
- [**Reason syntax**][reason-examples] &mdash; Several of the examples are
  written in Reason. See [**`r-hello`**][r-hello] and
  [**`r-fullstack-melange`**][melange].
- [**Examples**][examples] &mdash; These cover various HTTP scenarios.
- [**API reference**][api-main]

[tutorial]: https://github.com/aantron/dream/tree/master/example#readme
[examples]: https://github.com/aantron/dream/tree/master/example#examples
[1-hello]: https://github.com/aantron/dream/tree/master/example/1-hello#files
[r-hello]: https://github.com/aantron/dream/tree/master/example/r-hello#files
[reason-examples]: https://github.com/aantron/dream/tree/master/example#reason
[api-main]: https://aantron.github.io/dream/#types

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

Dream uses several [submodules][vendor], so be sure to clone with

```
git clone https://github.com/aantron/dream.git --recursive
```

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

- [ ] GraphQL subscriptions.
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
- [ ] Lots of helpers for decoupling defaults, e.g. forms without CSRF checking,
      SQL sessions with a different database.
- [ ] Bundle GraphiQL into a single HTML file that does not access any external
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
