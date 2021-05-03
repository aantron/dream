let welcome = {
  <html><head><style>a:visited {color: blue; text-decoration: none;}</style></head><body>
  <h1>Welcome to the Dream Playground!</h1>
  <p>Edit the code to the left, and press <strong>Run</strong> to recompile!</p>
  <p>Links:</p>
  <ul>
    <li><a target="_blank" href="https://github.com/aantron/dream">
      GitHub</a></li>
    <li><a target="_blank" href="https://github.com/aantron/dream/tree/master/example#readme">
      Tutorial</a></li>
    <li><a target="_blank" href="https://aantron.github.io/dream">
      API docs</a></li>
  </ul>
  </body>
}

let () =
  Dream.run(~interface="0.0.0.0")
  @@ Dream.logger
  @@ Dream.router([
    Dream.get("/", _ => Dream.html(welcome)),
  ])
  @@ Dream.not_found
