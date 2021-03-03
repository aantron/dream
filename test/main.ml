let () =
  Lwt_main.run @@ Dream.Httpaf.serve (fun _ -> assert false)
