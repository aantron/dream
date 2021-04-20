# `w-stress-websocket-send`

<br>

This example serves a client which opens four WebSockets. The server then floods
each WebSocket with 1 GB of data in 64 KB one-frame messages.

At the moment, the naive and unoptimized Dream massively outpaces Chrome. Dream
sends the 4 GB in about 8 seconds, at a resulting speed of about 4 Gbits/s.
Chrome appears to receive all the messages, but the JavaScript engine processes
them in about 10 minutes (55 Mbit/s), causing massive buffering in Chrome.

This test should be improved after flow control is added internally to Dream's
writers in [#34](https://github.com/aantron/dream/issues/34). It should probably
be run with multiple separate client tabs or processes, rather than one
JavaScript context.

<br>

[Up to the example index](../#examples)
