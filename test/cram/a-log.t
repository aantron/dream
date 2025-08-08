  $ log &> /dev/null &
  $ $CURL localhost:8080
  Good morning, world!
  $ $CURL localhost:8080/fail
  $ pkill -P $$
