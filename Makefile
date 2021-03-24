PACKAGES := dream,gluten,gluten-lwt,gluten-lwt-unix,websocketaf,httpaf,httpaf-lwt,httpaf-lwt-unix,h2,h2-lwt,h2-lwt-unix

.PHONY : build
build :
	@dune build --no-print-directory -p $(PACKAGES) @install

.PHONY : watch
watch :
	@dune build --no-print-directory -p $(PACKAGES) -w

# TODO LATER After https://github.com/aantron/bisect_ppx/issues/369, get rid of
# --root argument.
.PHONY : test
test :
	@find . -name '*.coverage' | xargs rm -f
	@dune build --no-print-directory \
	  --instrument-with bisect_ppx --root . --force @test/runtest
	@dune exec --no-print-directory -- bisect-ppx-report html
	@dune exec --no-print-directory -- bisect-ppx-report summary
	@echo See _coverage/index.html

.PHONY : test-watch
test-watch :
	@dune build --no-print-directory -w --root . @test/runtest

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

.PHONY : clean-coverage
clean-coverage :
	rm -rf _coverage

.PHONY : clean
clean : clean-coverage
	dune clean
	dune clean --root .
	make --no-print-directory -C docs/web clean

.PHONY : utop
utop :
	dune utop -p $(PACKAGES)

.PHONY : todo
todo :
	@git grep -n TODO | grep -v fw | grep -v DOC | grep -v LATER | grep -v SELF || true # SELF

.PHONY : todo-all
todo-all :
	@git grep -n TODO | grep -v SELF # SELF
