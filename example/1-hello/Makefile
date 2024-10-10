.PHONY : test
test :
	killall hello.exe || true
	dune exec -- ./hello.exe &
	sleep 1;
	bash -c "for (( i=0; i<2048; ++i )) ; do curl -s http://localhost:8080/ ; done"
