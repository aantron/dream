let home =
  <html>
    <body>
      <p></p>
      <script>
        var request = new XMLHttpRequest();
        request.open("POST", "/ajax", true);
        request.onload = function () {
          document.querySelector("p").innerText = request.responseText;
        };
        request.send();
      </script>
    </body>
  </html>

let count = ref 0

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get  "/"
      (fun _ ->
        Dream.respond home);

    Dream.post "/ajax" @@ Dream.origin_referer_check @@
      (fun _ ->
        incr count;
        Dream.respond ~headers:["Content-Type", "application/json"]
          (Printf.sprintf "{\"count\": %i}" !count));

  ]
  @@ Dream.not_found
