.PHONY : build
build :
	@dune build --no-print-directory

.PHONY : watch
watch :
	@dune build --no-print-directory -w

.PHONY : test
test :
	@tput rmam
	@stty -echo
	@dune exec --no-print-directory -- test/main.exe
	@tput smam

.PHONY : todo
todo :
	@git grep -n TODO | grep -v fw | grep -v DOC | grep -v LATER | grep -v SELF || true # SELF

.PHONY : todo-all
todo-all :
	@git grep -n TODO | grep -v SELF # SELF
