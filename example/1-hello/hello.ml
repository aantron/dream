let () =
  Eio_main.run (fun env ->
    Dream.run env (fun _ ->
      Dream.html "Good morning, world!")
  )
