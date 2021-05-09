# `w-fswatch`

<br>

This example sets up a simple development watcher using
[fswatch](https://github.com/emcrisostomo/fswatch), which is available in system
package managers such as APT and Homebrew:

```sh
#!/bin/bash

npx esy start &
fswatch -o hello.ml -l 2 | xargs -L1 bash -c \
  "killall hello.exe || true; (npx esy start || true) &"
```

<pre><code><b>$ cd example/w-fswatch</b>
<b>$ bash watch.sh</b></code></pre>

<br>

This watcher rebuilds `hello.exe` every time `hello.ml` changes. It's a bit
verbose and clunky, but it gets the job done. We may be able to offer a better
solution in the future.

The reason we are not suggesting `dune watch -w` is because it does not kill the
running server, which we are doing manually here, with the `killall` command.

As your project grows, replace `hello.ml` with the list of your source
directories. For example,

```
fswatch -o client server -l 2
```

<br>

**See also:**

- [**`w-live-reload`**](../w-live-reload#files) adds live reloading, so that
  browsers reload when the server is restarted.
- [**`w-esy`**](../w-esy#files) discusses [esy](https://esy.sh/) packaging.


<br>

[Up to the example index](../#examples)
