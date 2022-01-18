.PHONY : build

default:
	@dune build

build :
	@dune build -p dream-pure,dream-httpaf,dream --no-print-directory @install

.PHONY : watch
watch :
	@dune build -p dream-pure,dream-httpaf,dream --no-print-directory -w

TEST ?= test

.PHONY : test
test :
	@find . -name '*.coverage' | xargs rm -f
	@dune build --no-print-directory \
	  --instrument-with bisect_ppx --force @$(TEST)/runtest
	@bisect-ppx-report html
	@bisect-ppx-report summary
	@echo See _coverage/index.html

.PHONY : test-watch
test-watch :
	@dune build --no-print-directory -w --root . @$(TEST)/runtest

.PHONY : coverage-serve
coverage-serve :
	cd _coverage && dune exec -- serve -p 8082

.PHONY : promote
promote :
	dune promote --root .
	@make --no-print-directory test

.PHONY : docs
docs :
	make -C docs/web --no-print-directory
	@echo See docs/web/build/index.html

WATCH := \
	docs/web/site/docs.css \
	docs/web/site/docs.js \
	docs/web/site/*.md \
	src/dream.mli \
	docs/web/postprocess \
	docs/web/templates/*.html \
	docs/web/soupault.conf

.PHONY : docs-watch
docs-watch :
	fswatch -o $(WATCH) | xargs -L 1 -I FOO make docs --no-print-directory

.PHONY : docs-serve
docs-serve :
	cd docs/web/build && dune exec -- serve -p 8081

.PHONY : docs-publish
docs-publish : docs
	cp -r docs/web/build/* docs/web/gh-pages/
	cd docs/web/gh-pages && \
	  git commit -a --amend --no-edit && \
		git push --force-with-lease

.PHONY : clean-coverage
clean-coverage :
	rm -rf _coverage

.PHONY : clean
clean : clean-coverage
	dune clean
	dune clean --root .
	make --no-print-directory -C docs/web clean
	rm -rf src/graphiql/node_modules dream-* _release

.PHONY : test-ocamlformat
test-ocamlformat :
	touch test/ocamlformat/test.expect.ml
	ocamlformat test/ocamlformat/test.ml > test/ocamlformat/test.actual.ml
	diff -u3 test/ocamlformat/test.expect.ml test/ocamlformat/test.actual.ml

.PHONY : test-ocamlformat-promote
test-ocamlformat-promote :
	ocamlformat test/ocamlformat/test.ml > test/ocamlformat/test.expect.ml

.PHONY : utop
utop :
	dune utop

.PHONY : todo
todo :
	@git grep -n TODO | grep -v fw | grep -v DOC | grep -v LATER | grep -v SELF || true # SELF

.PHONY : todo-all
todo-all :
	@git grep -n TODO | grep -v SELF # SELF

VERSION := $(shell git describe --abbrev=0)
RELEASE := dream-$(VERSION)
FILES := src dream.opam dune-project LICENSE.md README.md

.PHONY : release
release : clean
	rm -rf $(RELEASE) $(RELEASE).tar $(RELEASE).tar.gz _release
	mkdir $(RELEASE)
	cp -r $(FILES) $(RELEASE)
	rm -rf $(RELEASE)/src/vendor/gluten/.github
	rm -rf $(RELEASE)/src/vendor/gluten/async
	rm -rf $(RELEASE)/src/vendor/gluten/mirage
	rm -rf $(RELEASE)/src/vendor/gluten/nix
	rm -rf $(RELEASE)/src/vendor/httpaf/.github
	rm -rf $(RELEASE)/src/vendor/httpaf/async
	rm -rf $(RELEASE)/src/vendor/httpaf/benchmarks
	rm -rf $(RELEASE)/src/vendor/httpaf/certificates
	rm -rf $(RELEASE)/src/vendor/httpaf/examples
	rm -rf $(RELEASE)/src/vendor/httpaf/images
	rm -rf $(RELEASE)/src/vendor/httpaf/lib_test
	rm -rf $(RELEASE)/src/vendor/httpaf/mirage
	rm -rf $(RELEASE)/src/vendor/httpaf/nix
	rm -rf $(RELEASE)/src/vendor/h2/.github
	rm -rf $(RELEASE)/src/vendor/h2/async
	rm -rf $(RELEASE)/src/vendor/h2/certificates
	rm -rf $(RELEASE)/src/vendor/h2/examples
	rm -rf $(RELEASE)/src/vendor/h2/lib_test
	rm -rf $(RELEASE)/src/vendor/h2/mirage
	rm -rf $(RELEASE)/src/vendor/h2/nix
	rm -rf $(RELEASE)/src/vendor/h2/spec
	rm -rf $(RELEASE)/src/vendor/h2/vegeta-plot.png
	rm -rf $(RELEASE)/src/vendor/websocketaf/.github
	rm -rf $(RELEASE)/src/vendor/websocketaf/async
	rm -rf $(RELEASE)/src/vendor/websocketaf/examples
	rm -rf $(RELEASE)/src/vendor/websocketaf/lib_test
	rm -rf $(RELEASE)/src/vendor/websocketaf/mirage
	rm -rf $(RELEASE)/src/vendor/websocketaf/nix
	tar cf $(RELEASE).tar $(RELEASE)
	ls -l $(RELEASE).tar
	gzip -9 $(RELEASE).tar
	mkdir -p _release
	cp $(RELEASE).tar.gz _release
	(cd _release && tar xf $(RELEASE).tar.gz)
	opam pin add -y --no-action dream _release/$(RELEASE) --kind=path
	opam reinstall -y --verbose dream
	cd example/1-hello && dune exec --root . ./hello.exe || true
	opam remove -y dream
	opam pin remove -y dream
	md5sum $(RELEASE).tar.gz
	ls -l $(RELEASE).tar.gz
