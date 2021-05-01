(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Sandboxes. *)

type syntax = [ `OCaml | `Reason ]

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

let sandbox_dune_re = {|(executable
 (name server)
 (libraries dream)
 (preprocess (pps lwt_ppx)))

(rule
 (targets server.re)
 (deps server.eml.re)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
|}

let base_dockerfile = {|FROM ubuntu:focal-20210416
RUN apt update && apt install -y openssl libev4
|}

let sandbox_dockerfile = {|FROM base:base
COPY _build/default/server.exe /server.exe
USER 112:3000
ENTRYPOINT /server.exe
|}

let create_sandboxes_directory () =
  match%lwt Lwt_unix.mkdir sandbox_root 0o755 with
  | () -> Lwt.return_unit
  | exception Unix.(Unix_error (EEXIST, _, _)) -> Lwt.return_unit

let exists sandbox =
  Lwt_unix.file_exists (sandbox_root // sandbox)

let write_file sandbox file content =
  Lwt_io.(with_file
    ~mode:Output (sandbox_root // sandbox // file) (fun channel ->
      write channel content))

let create_named sandbox syntax code =
  Dream.info (fun log -> log "Sandbox %s: creating" sandbox);
  begin match%lwt Lwt_unix.mkdir (sandbox_root // sandbox) 0o755 with
  | () -> Lwt.return_unit
  | exception Unix.(Unix_error (EEXIST, _, _)) -> Lwt.return_unit
  end;%lwt
  begin match syntax with
  | `OCaml -> write_file sandbox "server.eml.ml" code
  | `Reason -> write_file sandbox "server.eml.re" code
  end;%lwt
  Lwt.return sandbox

let rec create ?(attempts = 3) syntax code =
  match attempts with
  | 0 -> failwith "Unable to create sandbox directory"
  | attempts ->
    let sandbox = Dream.random 9 |> Dream.to_base64url in
    match%lwt exists sandbox with
    | true -> create ~attempts:(attempts - 1) syntax code
    | false -> create_named sandbox syntax code

let read sandbox =
  let ocaml_promise =
    Lwt_io.(with_file
      ~mode:Input (sandbox_root // sandbox // "server.eml.ml") read)
  in
  match%lwt ocaml_promise with
  | content -> Lwt.return (content, `OCaml)
  | exception _ ->
    let%lwt content =
      Lwt_io.(with_file
        ~mode:Input (sandbox_root // sandbox // "server.eml.re") read)
    in
    Lwt.return (content, `Reason)

let init_client socket content =
  `Assoc [
    "kind", `String "content";
    "payload", `String content;
  ]
  |> Yojson.Basic.to_string
  |> Dream.send socket

let validate_id sandbox =
  String.length sandbox > 0 && Dream.from_base64url sandbox <> None



(* Session state transitions. *)

type container = {
  container_id : string;
  port : int;
}

type session = {
  mutable container : container option;
  mutable sandbox : string;
  syntax : syntax;
  socket : Dream.websocket;
}

let allocated_ports =
  Hashtbl.create 256

let kill_container session =
  match session.container with
  | None -> Lwt.return_unit
  | Some {container_id; port} ->
    session.container <- None;
    Dream.info (fun log ->
      log "Sandbox %s: killing container %s" session.sandbox container_id);
    let%lwt _status =
      Printf.sprintf "docker kill %s > /dev/null 2> /dev/null" container_id
      |> Lwt_process.shell
      |> Lwt_process.exec
    in
    Hashtbl.remove allocated_ports port;
    Lwt.return_unit

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
  if Hashtbl.mem allocated_ports port then
    allocate_port ()
  else begin
    Hashtbl.replace allocated_ports port ();
    Lwt.return port
  end

let client_log ?(add_newline = false) session message =
  let message =
    if add_newline then message ^ "\n"
    else message
  in
  `Assoc [
    "kind", `String "log";
    "payload", `String message;
  ]
  |> Yojson.Basic.to_string
  |> Dream.send session.socket

let build session =
  let process =
    Printf.sprintf
      "cd %s && opam exec %s -- dune build --root . ./server.exe 2>&1"
      (sandbox_root // session.sandbox) "--color=always"
    |> Lwt_process.shell
    |> new Lwt_process.process_in in
  let%lwt output = Lwt_io.read process#stdout in
  Dream.info (fun log ->
    log "Sandbox %s: sending build output" session.sandbox);
  client_log session output;%lwt
  match%lwt process#close with
  | Unix.WEXITED 0 -> Lwt.return_true
  | _ ->
    Printf.ksprintf Sys.command
      "touch %s" (sandbox_root // session.sandbox // "failed") |> ignore;
    Lwt.return_false

let image session =
  let%lwt _status =
    Printf.sprintf
      "cd %s && docker build -t sandbox:%s . 2>&1"
      (sandbox_root // session.sandbox) session.sandbox
    |> Lwt_process.shell
    |> Lwt_process.exec
  in
  Dream.info (fun log -> log "Sandbox %s: built image" session.sandbox);
  Lwt.return_unit

let started session port =
  `Assoc [
    "kind", `String "started";
    "sandbox", `String session.sandbox;
    "port", `Int port;
  ]
  |> Yojson.Basic.to_string
  |> Dream.send session.socket

let rec make_container_id () =
  let candidate = Dream.random 9 |> Dream.to_base64url in
  match candidate.[0] with
  | '_' | '-' -> make_container_id ()
  | _ -> candidate

let run session =
  let alive, signal_alive = Lwt.wait () in
  let signalled = ref false in
  let signal_alive () =
    if !signalled then
      ()
    else begin
      signalled := true;
      Lwt.wakeup_later signal_alive ()
    end
  in
  let%lwt port = allocate_port () in
  let container_id = make_container_id () in
  session.container <- Some {container_id; port};
  Lwt.async begin fun () ->
    Printf.sprintf
      "docker run -p %i:8080 --name %s --rm -t sandbox:%s 2>&1"
      port container_id session.sandbox
    |> Lwt_process.shell
    |> Lwt_process.pread_lines
    |> Lwt_stream.iter_s (fun line ->
      signal_alive ();
      client_log ~add_newline:true session line)
  end;
  alive;%lwt
  started session port;%lwt
  Dream.info (fun log ->
    log "Sandbox %s: started %s on port %i" session.sandbox container_id port);
  Lwt.return_unit

let kill session =
  let%lwt () = kill_container session in
  Dream.close_websocket session.socket



(* Main loop for each connected client WebSocket. *)

(* We are running on a 1-CPU machine for now anyway, so it's not such a big
   deal to have a global (asynchronous) lock preventing concurrent builds and
   GC. *)
let global_lock =
  Lwt_mutex.create ()

(* TODO Mind concurrency issues with client messages coming during transitions.
   OTOH this code waits during those transitions anyway, so maybe it is not an
   issue. *)
let rec listen session =
  match%lwt Dream.receive session.socket with
  | None ->
    Dream.info (fun log -> log "WebSocket closed by client");
    kill session
  | Some code ->

  Dream.info (fun log -> log "Sandbox %s: code update" session.sandbox);
  kill_container session;%lwt

  Lwt_mutex.with_lock global_lock begin fun () ->

    let%lwt current_code, _ = read session.sandbox in
    if code = current_code then
      Lwt.return_unit
    else begin
      let%lwt sandbox = create session.syntax code in
      session.sandbox <- sandbox;
      Lwt.return_unit
    end;%lwt
    write_file session.sandbox "dune-project" sandbox_dune_project;%lwt
    begin match session.syntax with
    | `OCaml -> write_file session.sandbox "dune" sandbox_dune
    | `Reason -> write_file session.sandbox "dune" sandbox_dune_re
    end;%lwt
    write_file session.sandbox "Dockerfile" sandbox_dockerfile;%lwt

    begin match%lwt build session with
    | false -> Lwt.return_unit
    | true ->
      image session;%lwt
      run session
    end

  end;%lwt

  listen session

let listen session =
  try%lwt
    listen session
  with exn ->
    kill session;%lwt
    raise exn



let rec gc () =
  Lwt_mutex.with_lock global_lock begin fun () ->
    Sys.command
      ("docker rmi " ^
        "$(docker images | grep -v base | grep -v ubuntu | " ^
        "grep -v REPOSITORY | awk '{print $3}')") |> ignore;
    Sys.command "rm -rf sandbox/*/_build" |> ignore;
    Lwt.return_unit
  end;%lwt
  Lwt_unix.sleep 3600.;%lwt
  gc ()



(* Entry point. *)

let () =
  (* Make sure ./sandbox directory exists. *)
  Lwt_main.run (create_sandboxes_directory ());

  (* Create the default sandbox. *)
  Lwt_main.run (create_named "ocaml" `OCaml starter_server_eml_ml)
  |> ignore;

  (* Stop when systemd sends SIGTERM. *)
  let stop, signal_stop = Lwt.wait () in
  Lwt_unix.on_signal Sys.sigterm (fun _signal ->
    Lwt.wakeup_later signal_stop ())
  |> ignore;

  (* Start the sandbox gc. *)
  Lwt.async gc;

  (* Build the base image. *)
  Lwt_main.run begin
    Lwt_io.(with_file ~mode:Output "Dockerfile" (fun channel ->
      write channel base_dockerfile));%lwt
    Sys.command "docker build -t base:base . 2>&1" |> ignore;
    Lwt.return_unit
  end;

  (* Start the Web server. *)
  Dream.run ~interface:"0.0.0.0" ~port:80 ~stop ~adjust_terminal:false
  @@ Dream.logger
  @@ Dream.router [

    (* The client will send a default sandbox id in this case. *)
    Dream.get "/" (fun request ->
      Dream.from_filesystem "static" "playground.html" request);

    (* Upon request for /socket?sandbox=id, send the code in the sandbox to the
       client, and then enter the "REPL." Not bothering with nice replies or
       nice error handling here, because a valid client won't trigger them. If
       they occur, they are harmless to the server. *)
    Dream.get "/socket" (fun request ->
      match Dream.query "sandbox" request with
      | None -> Dream.empty `Bad_Request
      | Some sandbox ->
      match validate_id sandbox with
      | false -> Dream.empty `Bad_Request
      | true ->
      (* Read the sandbox. If the requested sandbox doesn't exist, this will
         raise an exception, causing a 500 reply to the JavaScript client. *)
      let%lwt content, syntax = read sandbox in
      Dream.websocket (fun socket ->
        init_client socket content;%lwt
        Dream.info (fun log ->
          log "Sandbox %s: content sent to client" sandbox);
        listen {container = None; sandbox; syntax; socket}));

    (* For sandbox ids, respond with the sandbox page. *)
    Dream.get "/:id" (fun request ->
      let sandbox = Dream.param "id" request in
      match validate_id sandbox with
      | false -> Dream.empty `Not_Found
      | true ->
      match%lwt exists sandbox with
      | false -> Dream.empty `Not_Found
      | true ->
      Dream.from_filesystem "static" "playground.html" request);

  ]
  @@ Dream.not_found;

  Dream.log "Exiting; killing all containers";
  Sys.command "docker kill $(docker ps -q) > /dev/null 2> /dev/null"
  |> ignore
