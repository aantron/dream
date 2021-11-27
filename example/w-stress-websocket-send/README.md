# `w-stress-websocket-send`

<br>

This example serves a client which opens four WebSockets. The server then floods
each WebSocket with 1 GB of data in 64 KB one-frame messages.

At the moment, Dream greatly outpaces Chrome, which appears to limit WebSocket
traffic to 64 MB/s per tab.

<br>

[Up to the example index](../#examples)
