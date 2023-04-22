open Eio.Std

let home =
  <html>
  <body>

  <pre id="output"></pre>

  <script>
  var output = document.querySelector("#output");

  var events = new EventSource("/push");
  events.onmessage = function (event) {
    output.appendChild(
      document.createTextNode(event.data + "\n"));
  };
  </script>

  </body>
  </html>

let server_state =
  ref []

let notify =
  ref ignore

let last_message =
  ref 0

let message_loop () =
  while true do
    Eio_unix.sleep (Random.float 2.);

    incr last_message;
    let message = string_of_int !last_message in
    Dream.log "Generated message %s" message;

    server_state := message::!server_state;
    !notify ()
  done

let rec forward_messages stream =
  let%lwt messages =
    match !server_state with
    | [] ->
      let on_message, notify_message = Lwt.wait () in
      notify := Lwt.wakeup_later notify_message;
      let%lwt () = on_message in
      notify := ignore;
      Lwt.return !server_state
    | messages ->
      Lwt.return messages
  in

  server_state := [];

  messages
  |> List.rev
  |> List.map (Printf.sprintf "data: %s\n\n")
  |> String.concat ""
  |> fun text ->
    let () = Dream.write stream text in
    let () = Dream.flush stream in
    forward_messages stream

let forward_messages response = Lwt_eio.run_lwt @@ fun () -> forward_messages response

let () =
  Eio_main.run @@ fun env ->
  Fiber.both
    message_loop
    (fun () ->
       Dream.run env
       @@ Dream.logger
       @@ Dream.router [

         Dream.get "/" (fun _ -> Dream.html home);

         Dream.get "/push" (fun _ ->
             Dream.stream
               ~headers:["Content-Type", "text/event-stream"]
               forward_messages);

    Dream.get "/push" (fun _ ->
      Dream.stream
        ~headers:["Content-Type", "text/event-stream"]
        forward_messages);

       ]
    )
