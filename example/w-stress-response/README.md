# `w-stress-response`

<br>

This example responds with very large data streams &mdash; 1 GB in 64 KB chunks
by default. To use,

<pre><code><b>$ cd example/w-stress-response</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b>
<b>$ curl http://localhost:8080 > /dev/null &</b></code></pre>

The `curl` command can be repeated for multiple concurrent clients, to check
fairness or other effects.

The URL supports query parameters: `?mb=16384` sets the total number of
megabytes to respond with (16 GB in this case), and `?chunk=128` changes the
chunk size used during writing (128 KB in this case).

<br>

Dream is currently able to peak out on my machine at about 10 Gbit/s.

<br>

[Up to the example index](../#examples)
