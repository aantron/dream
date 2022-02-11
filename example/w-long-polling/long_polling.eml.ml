let home =
  <html>
  <body>

  <pre id="output"></pre>

  <script>
  var output = document.querySelector("#output");

  function getMessages() {
    var request = new XMLHttpRequest();
    request.open("GET", "/poll", true);
    request.onload = function () {
      output.appendChild(
        document.createTextNode(request.responseText + "\n"));
      window.setTimeout(getMessages, Math.random() + 1);
    };
    request.send();
  };

  getMessages();
  </script>

  </body>
  </html>

type server_state =
  | Client_waiting of (string -> unit)
  | Messages_accumulating of string list

let server_state =
  ref (Messages_accumulating [])

let last_message =
  ref 0

let rec message_loop () =
  let%lwt () = Lwt_unix.sleep (Random.float 2.) in
  incr last_message;

  let message = string_of_int !last_message in
  Dream.log "Generated message %s" message;

  begin match !server_state with
  | Client_waiting f ->
    server_state := Messages_accumulating [];
    f message
  | Messages_accumulating list ->
    server_state := Messages_accumulating (message::list)
  end;

  message_loop ()

let () =
  Lwt.async message_loop;

  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/" (fun _ -> Dream.html home);

    Dream.get "/poll" (fun _ ->
      match !server_state with
      | Client_waiting _ ->
        Dream.empty `Unauthorized
      | Messages_accumulating [] ->
        let response_promise, respond = Lwt.wait () in
        server_state := Client_waiting (fun message ->
          Lwt.wakeup_later respond (Dream.response message));
        response_promise
      | Messages_accumulating messages ->
        server_state := Messages_accumulating [];
        Dream.html (String.concat "\n" (List.rev messages)));

  ]
