(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021-2023 Thibaut Mattio, Anton Bachin *)



module Message = Dream_pure.Message



let route =
  "/_livereload"

let retry_interval_ms =
  500



let script = Printf.sprintf
    {js|
var socketUrl = "ws://" + location.host + "%s";
var s = new WebSocket(socketUrl);

s.onopen = function(even) {
  console.debug("Live reload: WebSocket connection open");
};

s.onclose = function(even) {
  console.debug("Live reload: WebSocket connection closed");

  var retryIntervalMs = %i;

  function reload() {
    s2 = new WebSocket(socketUrl);

    s2.onerror = function(event) {
      setTimeout(reload, retryIntervalMs);
    };

    s2.onopen = function(event) {
      location.reload();
    };
  };

  reload();
};

s.onerror = function(event) {
  console.debug("Live reload: WebSocket error:", event);
};
|js}
    route retry_interval_ms



let livereload next_handler request =

  match Message.target request with
  | target when target = route ->
    Helpers.websocket @@ fun socket ->
    ignore (Helpers.receive socket);
    Message.close_websocket socket

  | _ ->
    let response = next_handler request in
    match Message.header response "Content-Type" with
    | Some ("text/html" | "text/html; charset=utf-8") ->
      let body = Message.body response in
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
        Soup.create_element "script" ~inner_text:script
        |> Soup.append_child head;
        soup
        |> Soup.to_string
        |> Message.set_body response;
        response
      end

    | _ -> response
