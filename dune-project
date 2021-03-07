(lang dune 2.7)
(implicit_transitive_deps false)

; TODO
; Note: implicit_transitive_deps is useful during massive development, but is
; probably best turned off when the project is in a steady state and for
; releases, because of issues like:
;
;   https://github.com/ocaml/dune/issues/3569
;
; This seems like it could cause builds of Dream to break due to packaging
; details changing in upstream deps. Even if this the underlying feature is
; added to the compiler as discussed in the issue, builds of Dream with earlier
; compiler versions will still be threatened.
