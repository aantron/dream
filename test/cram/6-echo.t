  $ echo-server &> /dev/null &
  $ $CURL localhost:8080/echo --data "Hello, world!"
  Hello, world!
  $ pkill -P $$
