  $ counter &> /dev/null &
  $ $CURL localhost:8080
  Responding to the 1. request!
  $ $CURL localhost:8080
  Responding to the 2. request!
  $ pkill -P $$
