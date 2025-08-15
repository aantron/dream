  $ error &> /dev/null &
  $ $CURL localhost:8080/bad | sed 's/::1:.*/::1:<omitted>/' | sed 's/dream.request_id: [^<]*/dream.request_id: <omitted>/'
  <html>
  <body>
    <h1>404 Not Found</h1>
    <pre>404 Not Found
  
  From: Application
  Blame: Client
  Severity: Warning
  
  Client: ::1:<omitted>
  
  GET /bad
  Host: localhost:8080
  User-Agent: curl/8.9.1
  Accept: */*
  
  dream.client: ::1:<omitted>
  dream.tls: false
  dream.request_id: <omitted>
  dream.fd: 6</pre>
  </body>
  </html>
  $ $CURL localhost:8080/fail | sed 's/::1:.*/::1:<omitted>/' | sed 's/dream.request_id: [^<]*/dream.request_id: <omitted>/'
  <html>
  <body>
    <h1>404 Not Found</h1>
    <pre>404 Not Found
  
  From: Application
  Blame: Client
  Severity: Warning
  
  Client: ::1:<omitted>
  
  GET /fail
  Host: localhost:8080
  User-Agent: curl/8.9.1
  Accept: */*
  
  dream.client: ::1:<omitted>
  dream.tls: false
  dream.request_id: <omitted>
  dream.fd: 6</pre>
  </body>
  </html>
  $ pkill -P $$
