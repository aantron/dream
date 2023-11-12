let () =
  Dream.run(~interface="0.0.0.0")
  @@ Dream.logger
  @@ Dream.router([
    Dream.get("/", _ => Dream.html(Playground.welcome)),
  ])
