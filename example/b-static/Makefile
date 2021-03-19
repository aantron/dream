.PHONY : run
run :
	@tput rmam || true
	@stty -echo || true
	@dune exec --no-print-directory -- ./static.exe
	@tput smam || true
