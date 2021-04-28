# `w-stress-response`

<br>

This example demonstrates how to setup hot reloading of the client HTML content.

It works by injecting a script in the HTML pages sent to clients that will initiate a WebSocket.

When the server restarts, the WebSocket connection is lost, at which point, the client will try to reconnect every 500ms for 5s.
If within these 5s the client is able to reconnect to the server, it will trigger a reload of the page.

This example plays very well with `w-fswatch`, which demonstrates how to restart the server every time the filesystem is modified.
When integrating the two examples, one is able to have a setup where the clients' pages are reloaded every time a file is modified.

<br>

[Up to the example index](../#examples)
