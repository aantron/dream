# `w-fswatch`

<br>

This example sets up a simple development watcher using
[fswatch](https://github.com/emcrisostomo/fswatch), which is available in system
package managers such as APT and Homebrew:

```sh
#!/bin/bash

EXE=hello.exe
dune exec --root . ./$EXE &
fswatch -o hello.ml -l 2 | xargs -L1 bash -c \
  "killall $EXE || true; (dune exec --root . ./$EXE || true) &"
```

<pre><code><b>$ bash watch.sh</b></code></pre>

<br>

This one rebuilds `hello.exe` every time `hello.ml` changes. It's a bit verbose
and clunky, but it gets the job done.

The reason we are not suggesting `dune watch -w` is because it does not kill the
running server, which we are doing manually with the `killall` command.

As your project grows, replace `hello.ml` with the list of your source
directories. For example,

```
fswatch -o client server -l 2
```

<br>

**See also:**

- [**`w-esy`**](../w-esy#files) shows [esy](https://esy.sh/) packaging.


<br>

[Up to the example index](../#examples)
