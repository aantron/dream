let home =
  <html>
  <body>
    <form>
      <input type="submit" value="Send">
      <input type="text" id="message" size="64" autofocus>
    </form>
    <script>
      let message = document.getElementById("message");
      let chat = document.querySelector("body");
      let socket = new WebSocket("ws://" + window.location.host + "/websocket");

      socket.onmessage = function (event) {
        let item = document.createElement("div");
        item.innerText = event.data;
        chat.appendChild(item);
      };

      document.querySelector("form").onsubmit = function () {
        if (socket.readyState != WebSocket.OPEN)
          return false;
        if (!message.value)
          return false;

        socket.send(message.value);
        message.value = "";
        return false;
      };
    </script>
  </body>
  </html>

let clients =
  Hashtbl.create 5

let connect =
  let last_client_id = ref 0 in
  fun websocket ->
    last_client_id := !last_client_id + 1;
    Hashtbl.replace clients !last_client_id websocket;
    !last_client_id

let disconnect client_id =
  Hashtbl.remove clients client_id

let send message =
  Hashtbl.to_seq_values clients
  |> List.of_seq
  |> Lwt_list.iter_p (fun client -> Dream.send client message)

let handle_client websocket =
  let client_id = connect websocket in
  let rec loop () =
    match%lwt Dream.receive websocket with
    | Some message ->
      let%lwt () = send message in
      loop ()
    | None ->
      disconnect client_id;
      Dream.close_websocket websocket
  in
  loop ()

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html home);

    Dream.get "/websocket"
      (fun _ -> Dream.websocket handle_client);

  ]
  @@ Dream.not_found
