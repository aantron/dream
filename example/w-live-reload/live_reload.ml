let livereload_script
    ?(retry_interval_ms = 500)
    ?(max_retry_ms = 5000)
    ?(route = "/_livereload")
    ()
  =
  Printf.sprintf
    {js|
var socketUrl = "ws://" + location.host + "%s"
var s = new WebSocket(socketUrl);

s.onopen = function(even) {
  console.log("WebSocket connection open.");
};

s.onclose = function(even) {
  console.log("WebSocket connection closed.");
  const innerMs = %i;
  const maxMs = %i;
  const maxAttempts = Math.round(maxMs / innerMs);
  let attempts = 0;
  function reload() {
    attempts++;
    if(attempts > maxAttempts) {
      console.error("Could not reconnect to dev server.");
      return;
    }

    s2 = new WebSocket(socketUrl);

    s2.onerror = function(event) {
      setTimeout(reload, innerMs);
    };

    s2.onopen = function(event) {
      location.reload();
    };
  };
  reload();
};

s.onerror = function(event) {
  console.error("WebSocket error observed:", event);
};
|js}
    route
    retry_interval_ms
    max_retry_ms

let inject_livereload_script
    ?(reload_script = livereload_script ())
    ()
    (next_handler : Dream.request -> Dream.response Lwt.t)
    (request : Dream.request)
    : Dream.response Lwt.t
  =
  let%lwt response = next_handler request in
  match Dream.header "Content-Type" response with
  | Some "text/html" | Some "text/html; charset=utf-8" ->
    let%lwt body = Dream.body response in
    let soup = Soup.parse body in
    let open Soup.Infix in
    (match soup $? "head" with
    | None ->
      Lwt.return response
    | Some head ->
      Soup.create_element "script" ~inner_text:reload_script
      |> Soup.append_child head;
      Lwt.return (Dream.with_body (Soup.to_string soup) response))
  | _ ->
    Lwt.return response

let livereload_route ?(path = "/_livereload") () =
  Dream.get path (fun _ ->
      Dream.websocket (fun socket ->
          Lwt.bind (Dream.receive socket) (fun _ ->
              Dream.close_websocket socket)))

let () =
  Dream.run
  @@ Dream.logger
  @@ inject_livereload_script ()
  @@ Dream.router [
    livereload_route ();
    Dream.get "/"
      (fun _ ->
        Dream.html "Good morning, world!");
  ]
  @@ Dream.not_found
