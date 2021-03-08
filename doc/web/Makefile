ROOT := ../..
ODOC := odoc/default/_doc/_html

.PHONY : build
build :
	dune build @doc --root $(ROOT) --no-print-directory --build-dir `pwd`/odoc
	cp $(ODOC)/dream/Dream/index.html site/api.html
	@echo soupault
	@opam exec -- dune exec --no-print-directory -- soupault

.PHONY : watch
watch :
	fswatch -o site soupault.conf templates | xargs -L 1 -I FOO \
	  opam exec -- dune exec --no-print-directory -- soupault

.PHONY : clean
clean :
	rm -rf build
	rm -f site/api.html
	rm -rf odoc

.PHONY : deps
deps :
	opam install --deps-only . --locked

.PHONY : refresh-deps
refresh-deps :
	opam install --deps-only .

.PHONY : lock
lock :
	opam lock
