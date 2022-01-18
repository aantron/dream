open Eio.Std

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

let message_loop clock =
  while true do
    Eio.Time.sleep clock (Random.float 2.);
    incr last_message;

    let message = string_of_int !last_message in
    Dream.log "Generated message %s" message;

    begin match !server_state with
      | Client_waiting f ->
        server_state := Messages_accumulating [];
        f message
      | Messages_accumulating list ->
        server_state := Messages_accumulating (message::list)
    end
  done

let () =
  Eio_main.run @@ fun env ->
  Fibre.both
    (fun () -> message_loop env#clock)
    (fun () ->
       Dream.run env
       @@ Dream.logger
       @@ Dream.router [

         Dream.get "/" (fun _ -> Dream.html home);

         Dream.get "/poll" (fun _ ->
             match !server_state with
             | Client_waiting _ ->
               Dream.empty `Unauthorized
             | Messages_accumulating [] ->
               let response_promise, respond = Promise.create () in
               server_state := Client_waiting (fun message ->
                   Promise.fulfill respond (Dream.response message));
               Promise.await response_promise
             | Messages_accumulating messages ->
               server_state := Messages_accumulating [];
               Dream.html (String.concat "\n" (List.rev messages)));

       ]
       @@ Dream.not_found
    )
