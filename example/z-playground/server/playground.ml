(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Sandbox files. *)

let (//) = Filename.concat

let sandbox_root = "sandbox"

let starter_server_eml_ml = {|let welcome =
  <html><head><style>a:visited {color: blue; text-decoration: none;}</style></head><body>
  <h1>Welcome to the Dream Playground!</h1>
  <p>Edit the code to the left, and press <strong>Run</strong> to recompile!</p>
  <p>Links:</p>
  <ul>
    <li><a target="_blank" href="https://github.com/aantron/dream">
      GitHub</a></li>
    <li><a target="_blank" href="https://github.com/aantron/dream/tree/master/example#readme">
      Tutorial</a></li>
    <li><a target="_blank" href="https://aantron.github.io/dream">
      API docs</a></li>
  </ul>
  </body>

let () =
  Dream.run ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html welcome);
  ]
  @@ Dream.not_found
|}

let sandbox_dune_project = {|(lang dune 2.0)
|}

let sandbox_dune = {|(executable
 (name server)
 (libraries dream)
 (preprocess (pps lwt_ppx)))

(rule
 (targets server.ml)
 (deps server.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
|}

let sandbox_dockerfile = {|FROM ubuntu:focal-20210416
RUN apt update && apt install -y openssl libev4
COPY _build/default/server.exe /server.exe
ENTRYPOINT /server.exe
|}

let write_file id file content =
  Lwt_io.(with_file ~mode:Output (sandbox_root // id // file) (fun channel ->
    write channel content))

let check_or_create id =
  let path = sandbox_root // id in
  if%lwt Lwt_unix.file_exists path then
    Lwt.return_unit
  else
    let%lwt () =
      match%lwt Lwt_unix.mkdir sandbox_root 0o755 with
      | () -> Lwt.return_unit
      | exception Unix.(Unix_error (EEXIST, _, _)) -> Lwt.return_unit
    in
    let%lwt () = Lwt_unix.mkdir path 0o755 in
    let%lwt () = write_file id "dune-project" sandbox_dune_project in
    let%lwt () = write_file id "dune" sandbox_dune in
    let%lwt () = write_file id "server.eml.ml" starter_server_eml_ml in
    let%lwt () = write_file id "Dockerfile" sandbox_dockerfile in
    Lwt.return_unit



(* Sandbox state transitions. *)

type container = {
  port : int;
}

type sandbox = {
  mutable id : string option;
  mutable container : container option;
  socket : Dream.websocket;
}

let sandbox_by_port =
  Hashtbl.create 256

let sandbox_by_id =
  Hashtbl.create 256

let min_port = 9000
let max_port = 9999

let next_port =
  ref min_port

(* This can fail if there is a huge number of sandboxes, or very large spikes in
   sandbox creation. However, the failure is not catastrophic. *)
let rec allocate_port () =
  let port = !next_port in
  incr next_port;
  let%lwt () =
    if !next_port > max_port then begin
      next_port := min_port;
      Lwt.pause ()
    end
    else
      Lwt.return_unit
  in
  if Hashtbl.mem sandbox_by_port port then
    allocate_port ()
  else
    Lwt.return port

let read sandbox =
  match sandbox.id with
  | None -> Lwt.return ""
  | Some id ->
    Lwt_io.(with_file ~mode:Input (sandbox_root // id // "server.eml.ml") read)

let validate_id id =
  String.length id = 12 && Dream.from_base64url id <> None

let build id =
  let command =
    Printf.ksprintf Lwt_process.shell
      "cd %s && opam exec --color=always -- dune build --root . ./server.exe 2>&1"
      (sandbox_root // id) in
  Lwt_process.pread command

let image id =
  let command =
    Printf.ksprintf Lwt_process.shell
      "cd %s && docker build -t sandbox:%s . 2>&1" (sandbox_root // id) id in
  Lwt_process.pread command

let forward ?(add_newline = false) sandbox message =
  let message =
    if add_newline then message ^ "\n"
    else message
  in
  `Assoc ["kind", `String "log"; "payload", `String message]
  |> Yojson.Basic.to_string
  |> fun message -> Dream.send sandbox.socket message

let started sandbox port =
  `Assoc ["kind", `String "started"; "payload", `Int port]
  |> Yojson.Basic.to_string
  |> fun message -> Dream.send sandbox.socket message

let run sandbox id =
  let%lwt port = allocate_port () in
  Hashtbl.replace sandbox_by_port port sandbox;
  Hashtbl.replace sandbox_by_id id sandbox;
  sandbox.container <- Some {port};
  Lwt.async begin fun () ->
    Printf.ksprintf Lwt_process.shell
      "docker run -p %i:8080 --name s-%s --rm -t sandbox:%s 2>&1"
      port id id
    |> Lwt_process.pread_lines
    |> Lwt_stream.iter_s (forward ~add_newline:true sandbox)
  end;
  Lwt.return port

let stop_container sandbox =
  match sandbox.id, sandbox.container with
  | Some id, Some container ->
    Printf.ksprintf Sys.command "docker kill s-%s" id |> ignore;
    Hashtbl.remove sandbox_by_port container.port;
    Hashtbl.remove sandbox_by_id id;
    Lwt.return_unit
  | _ -> Lwt.return_unit

(* TODO Forcibly stop after one second. *)
let stop sandbox =
  let%lwt () = stop_container sandbox in
  Dream.close_websocket sandbox.socket



(* Main loop for each connected client WebSocket. *)

(* TODO Mind concurrency issues with client messages coming during transitions.
   OTOH this code waits during those transitions anyway, so maybe it is not an
   issue. *)
let rec communicate sandbox =
  match%lwt Dream.receive sandbox.socket with
  | None ->
    Dream.info (fun log -> log "WebSocket closed by client");
    stop sandbox

  | Some message ->
    let values =
      (* TODO Raises. *)
      match Yojson.Basic.from_string message with
      | `Assoc ["kind", `String kind; "payload", `String payload] ->
        Some (kind, payload)
      | _ ->
        None
    in
    match values with
    | None -> stop sandbox
    | Some (kind, payload) ->
      match kind, sandbox with

      | "attach", _ ->
        let payload = String.sub payload 1 (String.length payload - 1) in
        if not (validate_id payload) then stop sandbox
        else
          let id = payload in
          let%lwt () = check_or_create id in
          sandbox.id <- Some id;
          let%lwt content = read sandbox in
          let%lwt () =
            `Assoc ["kind", `String "content"; "payload", `String content]
            |> Yojson.Basic.to_string
            |> fun s -> Dream.send sandbox.socket s
          in
          communicate sandbox

      | "run", {id = Some id; _} ->
        let%lwt () = stop_container sandbox in
        let%lwt () = write_file id "server.eml.ml" payload in
        let%lwt output = build id in
        let%lwt () = forward sandbox output in
        let%lwt output = image id in
        (* let%lwt () = forward sandbox output in *)
        ignore output;
        let%lwt port = run sandbox id in
        let%lwt () = Lwt_unix.sleep 0.25 in
        let%lwt () = started sandbox port in
        communicate sandbox

      | _ -> stop sandbox



(* The Web server proper. *)

let () =
  (* Stop when systemd sends SIGTERM. *)
  let stop, signal_stop = Lwt.wait () in
  Lwt_unix.on_signal Sys.sigterm (fun _signal ->
    Lwt.wakeup_later signal_stop ())
  |> ignore;

  Dream.run ~interface:"0.0.0.0" ~port:80 ~stop ~adjust_terminal:false
  @@ Dream.logger
  @@ Dream.router [

    (* Generate a fresh valid id for new visitors, and redirect. *)
    Dream.get "/" (fun request ->
      Dream.random 9
      |> Dream.to_base64url
      |> (^) "/"
      |> Dream.redirect request);

    (* Apply function communicate to WebSocket connections. *)
    Dream.get "/socket" (fun _ ->
      Dream.websocket (fun socket -> communicate {
        id = None;
        container = None;
        socket;
      }));

    (* For sandbox ids, respond with the sandbox page. *)
    Dream.get "/:id" (fun request ->
      if not (validate_id (Dream.param "id" request)) then
        Dream.empty `Not_Found
      else
        let%lwt response =
          Dream.from_filesystem "static" "playground.html" request in
        Dream.with_header "Content-Type" "text/html; charset=utf-8" response
        |> Lwt.return);

  ]
  @@ Dream.not_found;

  Sys.command "docker kill $(docker ps -q) > /dev/null 2> /dev/null"
  |> ignore
