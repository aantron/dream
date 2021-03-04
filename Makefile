.PHONY : build
build :
	@dune build --no-print-directory

.PHONY : test
test :
	@dune exec --no-print-directory -- test/main.exe

.PHONY : todo
todo :
	@git grep TODO | grep -v fw | grep -v DOC | grep -v LATER

.PHONY : all-todo
all-todo :
	@git grep TODO
