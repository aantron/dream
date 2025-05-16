# Cram tests guidelines
* Make the example available via the dune file, e.g. `env _ (binaries ../../example/1-hello/hello.exe)))`
* Use `$CURL` instead of `curl` as we need retries in case the server is not yet available.
* Pipe the output of the server to `/dev/null` as it includes timestamps.
* Run `pkill -P $$` to kill the server at the end of the test.
* Execute only one test at a time (e.g. `dune runtest -j1`) as the tests all use the same port
