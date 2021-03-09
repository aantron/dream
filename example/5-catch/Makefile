.PHONY : run
run :
	@tput rmam || true
	@stty -echo || true
	@dune exec --no-print-directory -- ./catch.exe
	@tput smam || true
