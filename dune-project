(lang dune 2.7)

(name dream)

(generate_opam_files true)

(source
 (github aantron/dream))

(authors "Anton Bachin <antonbachin@yahoo.com>")

(maintainers "Anton Bachin <antonbachin@yahoo.com>")

(documentation "https://aantron.github.io/dream")

(license MIT)

(package
 (name dream)
 (synopsis "Tidy, feature-complete Web framework")
 (description 
    "\| Dream is a feature-complete Web framework with a simple programming
    "\| model and no boilerplate. It provides only two data types, request and
    "\| response.
    "\| 
    "\| Almost everything else is either a built-in OCaml type, or an
    "\| abbreviation for a bare function. For example, a Web app, known in
    "\| Dream as a handler, is just an ordinary function from requests to
    "\| responses. And a middleware is then just a function from handlers to
    "\| handlers.
    "\| 
    "\| Within this model, Dream adds:
    "\| 
    "\| - Session management with pluggable back ends.
    "\| - A fully composable router.
    "\| - Support for HTTP/1.1, HTTP/2, and HTTPS.
    "\| - WebSockets.
    "\| - GraphQL, including subscriptions and a built-in GraphiQL editor.
    "\| - SQL connection pool helpers.
    "\| - Server-side HTML templates.
    "\| - Automatic secure handling of cookies and forms.
    "\| - Unified, internationalization-friendly error handling.
    "\| - A neat log, and OCaml runtime configuration.
    "\| - Helpers for Web formats, such as Base64url, and a modern cipher.
    "\| 
    "\| Because of the simple programming model, everything is optional and
    "\| composable. It is trivially possible to strip Dream down to just a
    "\| bare driver of the various HTTP protocols.
    "\| 
    "\| Dream is presented as a single module, whose API is documented on one
    "\| page. In addition, Dream comes with a large number of examples.
    "\| Security topics are introduced throughout, wherever they are
    "\| applicable.
 )
 (depends
  base-unix
  bigarray-compat
  camlp-streams
  (caqti
   (>= 2.0.0))
  (caqti-lwt
   (>= 2.0.0))
  (conf-libev (<> :os win32))
  (ocaml (= :os win32))
  (cstruct
   (>= 6.0.0))
  (digestif
   (>= 0.7)) ; to_raw_string
  (dream-httpaf
   (>= 1.0.0~alpha3))
  (dream-pure
   (>= 1.0.0~alpha2))
  (fmt
   (>= 0.8.7)) ; `Italic
  graphql_parser
  graphql-lwt
  (lambdasoup
   (>= 0.6.1))
  lwt
  (lwt_ppx
   (>= 1.2.2))
  lwt_ssl
  (logs
   (>= 0.5.0))
  magic-mime
  (markup
   (>= 1.0.2))
  (mirage-clock
   (>= 3.0.0)) ; now_d_ps : unit -> int * int64
  (mirage-crypto
   (>= 1.0.0))
  (mirage-crypto-rng
   (>= 1.0.0))
  mirage-crypto-rng-lwt
  (multipart_form
   (>= 0.4.0))
  multipart_form-lwt
  (ocaml
   (>= 4.08.0))
  (ptime
   (>= 0.8.1)) ; Ptime.v
  (ssl
   (>= 0.5.8)) ; Ssl.get_negotiated_alpn_protocol
  (uri
   (>= 4.2.0))
  yojson ; ...
  ; Testing, development.
  (alcotest :with-test)
  (bisect_ppx
   (and
    :with-test
    (>= 2.5.0))) ; --instrument-with.
  (caqti-driver-postgresql :with-test)
  (caqti-driver-sqlite3 :with-test)
  (crunch :with-test)
  (html_of_jsx :with-test)
  (js_of_ocaml :with-test)
  (js_of_ocaml-ppx :with-test)
  (ppx_expect
   (and
    :with-test
    (>= v0.15.0))) ; Formatting changes.
  (ppx_yojson_conv :with-test)
  (reason :with-test)
  (tyxml
   (and
    :with-test
    (>= 4.5.0)))
  (tyxml-jsx :with-test))
 (tags
  (http web framework websocket graphql server http2 tls)))

(package
 (name dream-pure)
 (synopsis "Internal: shared HTTP types for Dream (server) and Hyper (client)")
 (description "This package does not have a stable API.")
 (depends
  (base64 (>= 3.1.0))  ; Base64.encode_string.
  (bigstringaf (>= 0.5.0))  ; Bigstringaf.to_string.
  hmap
  lwt
  (lwt_ppx (>= 1.2.2))
  (ocaml (>= 4.08.0))
  (ptime (>= 0.8.1))  ; Ptime.weekday.
  (uri (>= 4.2.0))

  ; Testing, development.
  (alcotest :with-test)
  (bisect_ppx (and :with-test (>= 2.5.0)) )  ; --instrument-with.
  (ppx_expect :with-test)
  (ppx_yojson_conv :with-test))
 (tags
  ()))

(package
 (name dream-httpaf)
 (synopsis "Internal: shared http/af stack for Dream (server) and Hyper (client)")
 (description "This package does not have a stable API.")
 (depends
  dream-pure
  lwt
  (lwt_ppx (>= 1.2.2))
  lwt_ssl
  (ocaml (>= 4.08.0))
  (ssl (>= 0.5.8))  ; Ssl.get_negotiated_alpn_protocol.

  ; Currently vendored.
  ; gluten
  ; gluten-lwt-unix
  ; httpaf
  ; httpaf-lwt-unix
  ; h2
  ; h2-lwt-unix
  ; hpack
  ; websocketaf

  ; Dependencies of vendored packages.
  (angstrom (>= 0.14.0))
  (base64 (>= 3.0.0))
  (bigstringaf (>= 0.5.0))  ; h2.
  (digestif (>= 0.7.2))  ; websocket/af, sha1, default implementation.
  (faraday (>= 0.6.1))
  faraday-lwt-unix
  (lwt_ssl (>= 1.2.0))  ; Gluten.
  psq)  ; h2.
 (tags
  ()))

(package
 (name dream-mirage)
 (synopsis "Tidy, feature-complete Web framework")
 (description
    "\| Dream is a feature-complete Web framework with a simple programming
    "\| model and no boilerplate. It provides only two data types, request and
    "\| response.
    "\| 
    "\| Almost everything else is either a built-in OCaml type, or an
    "\| abbreviation for a bare function. For example, a Web app, known in
    "\| Dream as a handler, is just an ordinary function from requests to
    "\| responses. And a middleware is then just a function from handlers to
    "\| handlers.
    "\| 
    "\| Within this model, Dream adds:
    "\| 
    "\| - Session management with pluggable back ends.
    "\| - A fully composable router.
    "\| - Support for HTTP/1.1, HTTP/2, and HTTPS.
    "\| - WebSockets.
    "\| - GraphQL, including subscriptions and a built-in GraphiQL editor.
    "\| - SQL connection pool helpers.
    "\| - Server-side HTML templates.
    "\| - Automatic secure handling of cookies and forms.
    "\| - Unified, internationalization-friendly error handling.
    "\| - A neat log, and OCaml runtime configuration.
    "\| - Helpers for Web formats, such as Base64url, and a modern cipher.
    "\| 
    "\| Because of the simple programming model, everything is optional and
    "\| composable. It is trivially possible to strip Dream down to just a
    "\| bare driver of the various HTTP protocols.
    "\| 
    "\| Dream is presented as a single module, whose API is documented on one
    "\| page. In addition, Dream comes with a large number of examples.
    "\| Security topics are introduced throughout, wherever they are
    "\| applicable.
 )
 (depends
  bigarray-compat
  bigstringaf
  (digestif (>= 1.0.0))
  dream
  dream-httpaf
  dream-pure
  duration
  (emile (>= 1.1))
  (ke (>= 0.4))  ; paf.
  (letsencrypt (>= 0.3.0))
  lwt
  (lwt_ppx (>= 1.2.2))
  (mimic (>= 0.0.5))
  mirage-time
  rresult
  tcpip
  tls-mirage)
 (tags
  (http web framework websocket graphql server http2 tls)))
