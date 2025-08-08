  $ router &> /dev/null &
  $ $CURL localhost:8080/echo/hello-world
  hello-world
  $ pkill -P $$
