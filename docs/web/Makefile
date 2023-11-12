	ROOT := ../..
ODOC := odoc/default/_doc/_html

.PHONY : build
build :
	dune build @doc --root $(ROOT) --no-print-directory --build-dir `pwd`/odoc \
	  --only-packages dream-pure,dream-httpaf,dream
	rm -f site/index.html
	dune exec -- postprocess/index.exe \
	  $(ODOC)/dream/Dream/index.html site/index.html
	rm -f site/status/index.html
	@echo soupault
	@dune exec --no-print-directory -- soupault

.PHONY : watch
watch :
	fswatch -o site soupault.conf templates | xargs -L 1 -I FOO \
	  dune exec --no-print-directory -- soupault

.PHONY : clean
clean :
	rm -rf build
	rm -f site/index.html
	rm -f site/status.html
	rm -rf odoc
	rm -f actual

.PHONY : deps
deps :
	opam install --deps-only . --locked
	npm install

.PHONY : refresh-deps
refresh-deps :
	opam install --deps-only .
	npm install

.PHONY : lock
lock :
	opam lock
