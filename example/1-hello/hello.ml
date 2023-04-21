let () =
  Dream.run ~builtins:true (fun _ ->
    Dream.html ~headers:["hey", "hi"; "",""] "Good morning, world!")
