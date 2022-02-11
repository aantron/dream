let home =
  <html>
  <body>
    <iframe src="/nested"></iframe>
  </body>
  </html>

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.html home);

    Dream.get "/nested" (fun _ ->
      Dream.html
        ~headers:["Content-Security-Policy",
          "frame-ancestors 'none'; " ^
          "report-uri /violation"]
        "You should not be able to see this inside a frame!");

    Dream.post "/violation" (fun request ->
      let%lwt report = Dream.body request in
      Dream.error (fun log -> log "%s" report);
      Dream.empty `OK);

  ]
