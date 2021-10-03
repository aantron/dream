Start a Dream server

  $ ./econnreset.exe -s -p 9191 &> test.log &
  $ export PID=$!
  $ sleep 1

Force a connection reset - will log a few errors

  $ ./econnreset.exe -p 9191

Does the log contain an error line for the ECONNRESET? An error code of [1] is "good", meaning no line was found.

  $ kill "${PID}"
  $ cat test.log | grep 'ERROR' | grep 'ECONNRESET'

Does the log contain an info line with custom string for the ECONNRESET?

  $ cat test.log | grep 'INFO' | grep 'Connection Reset at Client' | wc -l
