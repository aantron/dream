.PHONY : run
run :
	@tput rmam || true
	@stty -echo || true
	@dune exec --no-print-directory -- ./echo.exe
	@tput smam || true
