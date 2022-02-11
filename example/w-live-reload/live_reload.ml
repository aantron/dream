let live_reload_script = {js|

var socketUrl = "ws://" + location.host + "/_live-reload"
var socket = new WebSocket(socketUrl);

socket.onclose = function(event) {
  const intervalMs = 100;
  const attempts = 100;
  let attempt = 0;

  function reload() {
    ++attempt;

    if(attempt > attempts) {
      console.error("Could not reconnect to server");
      return;
    }

    reconnectSocket = new WebSocket(socketUrl);

    reconnectSocket.onerror = function(event) {
      setTimeout(reload, intervalMs);
    };

    reconnectSocket.onopen = function(event) {
      location.reload();
    };
  };

  reload();
};

|js}

let inject_live_reload_script inner_handler request =
  let%lwt response = inner_handler request in

  match Dream.header response "Content-Type" with
  | Some "text/html; charset=utf-8" ->
    let%lwt body = Dream.body response in
    let soup =
      Markup.string body
      |> Markup.parse_html ~context:`Document
      |> Markup.signals
      |> Soup.from_signals
    in

    begin match Soup.Infix.(soup $? "head") with
    | None ->
      Lwt.return response
    | Some head ->
      Soup.create_element "script" ~inner_text:live_reload_script
      |> Soup.append_child head;
      Dream.set_body response (Soup.to_string soup);
      Lwt.return response
    end

  | _ ->
    Lwt.return response

let () =
  Dream.run
  @@ Dream.logger
  @@ inject_live_reload_script
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.random 3
      |> Dream.to_base64url
      |> Printf.sprintf "Good morning, world! Random tag: %s"
      |> Dream.html);

    Dream.get "/_live-reload" (fun _ ->
      Dream.websocket (fun socket ->
        let%lwt _ = Dream.receive socket in
        Dream.close_websocket socket));

  ]
