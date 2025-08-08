  $ form &> /dev/null &
  $ $CURL localhost:8080 -c cookies -b cookies | sed 's/value=.*/value=<omitted>/'
  <html>
  <body>
  
  
    <form method="POST" action="/">
      <input name="dream.csrf" type="hidden" value=<omitted>
  
      <input name="message" autofocus>
    </form>
  
  </body>
  </html>
  
  $ $CURL localhost:8080 -X POST
  $ $CURL localhost:8080 -c cookies -b cookies | sed 's/value=.*/value=<omitted>/'
  <html>
  <body>
  
  
    <form method="POST" action="/">
      <input name="dream.csrf" type="hidden" value=<omitted>
  
      <input name="message" autofocus>
    </form>
  
  </body>
  </html>
  
  $ pkill -P $$
