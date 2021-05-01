# `w-stress-response`

<br>

This example responds with very large data streams &mdash; 1 GB in 64 KB chunks
by default. To use,

<pre><code><b>$ cd example/w-stress-response</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b>
<b>$ curl http://localhost:8080 > /dev/null &</b></code></pre>

The `curl` command can be repeated for multiple concurrent clients.

<br>

Writing currently slows down for very large streams. This is likely due to the
lack of server-side flow control for writers, which probably causes allocation
of huge internal buffers, which first triggers needless GC, and eventually page
thrashing at the virtual memory level.
[#34](https://github.com/aantron/dream/issues/34) should address this in one of
the early releases of Dream.

Nonetheless, for smaller streams, unoptimized Dream is able to peak out at
about 8 Gbits/s, which is more than one curl client can handle (2 Gbits/s).

<br>

[Up to the example index](../#examples)
