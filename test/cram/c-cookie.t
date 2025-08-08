  $ cookie &> /dev/null &
The cookie is encrypted so we have cannot set it ourselves
  $ $CURL localhost:8080 -c cookie
  Set language preference; come again!
  $ $CURL localhost:8080 -b cookie
  Your preferred language is ut-OP!
  $ pkill -P $$
