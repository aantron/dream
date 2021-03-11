PACKAGES := dream,gluten,gluten-lwt,gluten-lwt-unix,websocketaf,httpaf,httpaf-lwt,httpaf-lwt-unix,h2,h2-lwt,h2-lwt-unix

.PHONY : build
build :
	@dune build --no-print-directory -p $(PACKAGES)

.PHONY : watch
watch :
	@dune build --no-print-directory -p $(PACKAGES) -w

# TODO LATER After https://github.com/aantron/bisect_ppx/issues/369, get rid of
# --root argument.
.PHONY : test
test :
	@find . -name '*.coverage' | xargs rm -f
	@opam exec -- \
	  dune build --no-print-directory \
	  --instrument-with bisect_ppx --root . --force @test/runtest
	@opam exec -- dune exec --no-print-directory -- bisect-ppx-report html
	@opam exec -- dune exec --no-print-directory -- bisect-ppx-report summary
	@echo See _coverage/index.html

.PHONY : test-watch
test-watch :
	@dune build --no-print-directory -w --root . @test/runtest

.PHONY : promote
promote :
	dune promote --root .
	@make --no-print-directory test

.PHONY : clean-coverage
clean-coverage :
	rm -rf _coverage

.PHONY : clean
clean : clean-coverage
	dune clean
	dune clean --root .
	make --no-print-directory -C docs/web clean

.PHONY : todo
todo :
	@git grep -n TODO | grep -v fw | grep -v DOC | grep -v LATER | grep -v SELF || true # SELF

.PHONY : todo-all
todo-all :
	@git grep -n TODO | grep -v SELF # SELF
