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
  let response = inner_handler request in

  match Dream.header response "Content-Type" with
  | Some "text/html; charset=utf-8" ->
    let body = Dream.body response in
    let soup =
      Markup.string body
      |> Markup.parse_html ~context:`Document
      |> Markup.signals
      |> Soup.from_signals
    in

    begin match Soup.Infix.(soup $? "head") with
    | None ->
      response
    | Some head ->
      Soup.create_element "script" ~inner_text:live_reload_script
      |> Soup.append_child head;
      Dream.set_body response (Soup.to_string soup);
      response
    end

  | _ ->
    response

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ inject_live_reload_script
  @@ Dream.router [

    Dream.get "/" (fun _ ->
      Dream.random 3
      |> Dream.to_base64url
      |> Printf.sprintf "Good morning, world! Random tag: %s"
      |> Dream.html);

    Dream.get "/_live-reload" (fun request ->
      Dream.websocket request (fun socket ->
        let _ = Dream.read socket in
        Dream.close socket));

  ]
  @@ Dream.not_found
