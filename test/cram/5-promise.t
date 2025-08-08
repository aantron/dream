  $ promise &> /dev/null &
  $ $CURL localhost:8080
    0 request(s) successful<br>  0 request(s) failed
  $ curl --no-progress-meter localhost:8080/fail
  $ $CURL localhost:8080
    1 request(s) successful<br>  1 request(s) failed
  $ pkill -P $$
