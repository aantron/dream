  $ session &> /dev/null &
  $ $CURL localhost:8080 -c cookie
  You weren't logged in; but now you are!
  $ $CURL localhost:8080 -b cookie
  Welcome back, alice!
  $ pkill -P $$
