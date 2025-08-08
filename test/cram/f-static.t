  $ mkdir testdata
  $ echo "Hello" > hello
  $ echo "World" > testdata/world
  $ static &> /dev/null &
  $ $CURL localhost:8080/static/hello
  Hello
  $ $CURL localhost:8080/static/testdata/world
  World
  $ pkill -P $$
