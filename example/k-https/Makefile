.PHONY : run
run :
	@tput rmam || true
	@stty -echo || true
	@dune exec --no-print-directory -- ./ssl.exe
	@tput smam || true
