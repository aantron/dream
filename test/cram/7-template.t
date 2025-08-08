  $ template &> /dev/null &
  $ $CURL localhost:8080/hello-world
  <html>
  <body>
    <h1>The URL parameter was hello-world!</h1>
  </body>
  </html>
  
  $ pkill -P $$
