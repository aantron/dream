open Eio.Std

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

let clients : (int, Dream.response) Hashtbl.t =
  Hashtbl.create 5

let track =
  let last_client_id = ref 0 in
  fun websocket ->
    last_client_id := !last_client_id + 1;
    Hashtbl.replace clients !last_client_id websocket;
    !last_client_id

let forget client_id =
  Hashtbl.remove clients client_id

let send message =
  Switch.run @@ fun sw ->
  Hashtbl.to_seq_values clients
  |> List.of_seq
  |> List.iter (fun client ->
      Fibre.fork ~sw (fun () -> Dream.write client message)
    )

let handle_client client =
  let client_id = track client in
  let rec loop () =
    match Dream.read client with
    | Some message ->
      send message;
      loop ()
    | None ->
      forget client_id;
      Dream.close client
  in
  loop ()

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ -> Dream.html home);

    Dream.get "/websocket"
      (fun request -> Dream.websocket request handle_client);

  ]
  @@ Dream.not_found
