.PHONY : run
run :
	@tput rmam || true
	@stty -echo || true
	@dune exec --no-print-directory -- ./middleware.exe
	@tput smam || true
