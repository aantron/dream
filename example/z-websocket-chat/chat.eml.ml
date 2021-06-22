let home =
  <!DOCTYPE html>
  <html lang="en">
  <head>
  <title>Chat Example</title>
  <script type="text/javascript">
  window.onload = function () {
      let myId = Math.random().toString();
      let conn = new WebSocket("ws://" + window.location.host + "/websocket");

      conn.onmessage = function (evt) {
          let messages = evt.data.split('\n');
          for (let i = 0; i < messages.length; i++) {
              let item = document.createElement("div");
              item.innerText = messages[i];
              chat.appendChild(item);
          }
      };

      let msg = document.getElementById("msg");
      let chat = document.getElementById("chat");

      document.getElementById("form").onsubmit = function () {
          if (!conn) {
              return false;
          }
          if (!msg.value) {
              return false;
          }
          conn.send(myId + ":" + msg.value);
          msg.value = "";
          return false;
      };

  };
  </script>
  <style type="text/css">
  html {
      overflow: hidden;
  }

  body {
      overflow: hidden;
      padding: 0;
      margin: 0;
      width: 100%;
      height: 100%;
      background: gray;
  }

  #chat {
      background: white;
      margin: 0;
      padding: 1em;
      position: absolute;
      top: 0.5em;
      left: 0.5em;
      right: 0.5em;
      bottom: 3em;
      overflow: auto;
  }

  #form {
      padding: 0 0.5em 0 0.5em;
      margin: 0;
      position: absolute;
      bottom: 1em;
      left: 0px;
      width: 100%;
      overflow: hidden;
  }

  </style>
  </head>
  <body>
  <div id="chat"></div>
  <form id="form">
      <input type="submit" value="Send" />
      <input type="text" id="msg" size="64" autofocus />
  </form>
  </body>
  </html>

module Socket = struct
  let connections = Hashtbl.create 5

  let add key websocket =
    Hashtbl.replace connections key websocket

  let send msg =
    let websockets = Hashtbl.to_seq_values connections |> List.of_seq in
    Lwt_list.iter_p (fun w -> Dream.send w msg) websockets

  let remove key =
    Hashtbl.remove connections key 
end

let rec sockets ?(key=None) websocket =
  let close () =
    let () = match key with
    | None -> ()
    | Some key -> Socket.remove key
    in
    Dream.close_websocket websocket
  in
  match%lwt Dream.receive websocket with
  | Some text ->
      begin
      match String.split_on_char ':' text with 
      | [key; msg] -> 
          Socket.add key websocket;
          let%lwt () = Socket.send msg in
          sockets websocket ~key:(Some key)
      | _ -> close ()
      end
  | _ ->
      close ()

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [

    Dream.get "/"
      (fun _ ->
        Dream.html home);

    Dream.get "/websocket"
      (fun _ ->
        Dream.websocket sockets);

  ]
  @@ Dream.not_found
