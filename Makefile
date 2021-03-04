.PHONY : build
build :
	@dune build --no-print-directory

.PHONY : test
test :
	@tput rmam
	@stty -echo
	@dune exec --no-print-directory -- test/main.exe
	@tput smam

.PHONY : todo
todo :
	@git grep -n TODO | grep -v fw | grep -v DOC | grep -v LATER | grep -v SELF # SELF

.PHONY : all-todo
all-todo :
	@git grep -n TODO | grep -v SELF # SELF
