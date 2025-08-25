# Contributing to Dream

Contributions are very welcome. This includes not only code PRs, but also:

- [Examples](https://github.com/aantron/dream/tree/master/example#readme)
- [Docs fixes](https://aantron.github.io/dream/)
- [Bug reports](https://github.com/aantron/dream/issues)
- Links to [blogs](https://github.com/aantron/dream#example-repositories)
  &mdash; different people benefit from different presentations!
- Links to projects that use Dream &mdash; to serve as large examples
- Links to [libraries](https://github.com/aantron/dream#recommended-projects)
  to use with Dream
- And more!

<br>

## Bugs

To get the version of Dream installed in a project that uses it, run

```
opam list dream
```

or

```
npx esy ls-builds
```

<br>

## Code

If you'd like to contribute code, clone the repository with

```
git clone https://github.com/aantron/dream.git
cd dream
```

Later, you'll need to fork the repository on GitHub, and add your fork as a
remote:

```
git remote add fork git@github.com:my-github-name/dream.git
```

Install Dream's dependencies:

```
make deps
```

If you don't have an opam switch ready, first create one with

```
opam switch create . 4.14.1 --no-install
```

You can now add some code that will exercise your change, so you can test it as
you work. There are two main places for this:

1. The tests in `test/`. They can be run with `make test`. View the generated
   coverage report in `_coverage/index.html` to see how much the tests exercise
   your changes.

   To run tests from a single directory, for example `test/expect/pure`, run
   `make test TEST=test/expect/pure`.

2. The tests can also be run in watch mode using `make test-watch`. This is not
   compatible with coverage reports at the moment.

3. The examples in `example/`. I often test changes by modifying an example that
   is almost on topic for the code I'm changing, and then not committing the
   example. In some cases, though, it's easiest to fork or write a new example
   for some new code, and commit it. New examples greatly appreciated! To build
   any of the examples against your own clone of Dream, do

   ```
   cd example/1-hello
   dune exec ./hello.exe
   ```

   Make sure *not* to run `esy` using the commands given in each example, nor
   use `--root .`, as these options both will sandbox the build, and build
   against a published version of Dream (whether in a package manager or on
   GitHub), rather than against your local clone.

Commit the code and push to your fork:

```
git add .
git commit
git push -u fork my-branch
```

GitHub should print a URL into your terminal for opening a pull request.

**Note:** Please don't force-push into a PR &mdash; it makes incremental review
very difficult, and we will squash-merge most PRs anyway!

**Note:** Please don't resolve conversations in PRs. Reviewers use resolving
conversations to keep track of what has been addressed.

<br>

If you need to link to the local version of Dream from a project that lives in
a different directory, and you are using esy, add this line to your `esy.json`:

```json
{
   ...
   "resolutions": {
     ...
     "@opam/dream": "link:path/to/dream.opam"
   },
}
```

Then, run
```
npx esy install
npx esy build
npx esy start
```

Don't forget the `esy build` step, which is necessary to build the local
dependency.

<br>

## Docs

To build the docs, go to
[`docs/web/`](https://github.com/aantron/dream/tree/master/docs/web) and run

```
make deps
```

This will install npm and opam packages. In particular, the site currently
requires odoc 2.0.2, Soupault, and a specific version of Highlight.js.

After that, back in the project root,

```
cd ../..
```

Run

```
make docs
```

to build the docs locally. They are output to `docs/web/build/index.html`.

You can also use

```
make docs-watch
```

to rebuild the docs automatically as you write them.
