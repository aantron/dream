# `z-playground`

<br>

This “example” is, in fact, the Dream online playground, running at
[http://dream.as](http://dream.as).

It's a simple, one-page app that uses a WebSocket to communicates with its
server. The server starts and stops Docker containers that run visitors' code.
An `<iframe>` serves as an on-page client for testing out Web apps.

The playground is packaged a systemd daemon.

<br>

**See also:**

- [**`k-websocket`**](../k-websocket#files) introduces WebSockets.
- [**`z-systemd`**](../z-systemd#files) packages a tiny app for management by
  systemd.

<br>

[Up to the example index](../#examples)
