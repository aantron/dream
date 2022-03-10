(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Sandboxes. *)

type syntax = [ `OCaml | `Reason ]

let (//) = Filename.concat

let sandbox_root = "sandbox"

let sandbox_dune = {|(executable
 (name server)
 (libraries caqti caqti-driver-sqlite3 dream runtime tyxml)
 (preprocess (pps lwt_ppx ppx_yojson_conv)))

(rule
 (targets server.ml)
 (deps server.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
|}

let sandbox_dune_re = {|(executable
 (name server)
 (libraries caqti caqti-driver-sqlite3 dream runtime tyxml)
 (preprocess (pps lwt_ppx ppx_yojson_conv)))

(rule
 (targets server.re)
 (deps server.eml.re)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
|}

let sandbox_dune_no_eml = {|(executable
 (name server)
 (libraries caqti caqti-driver-sqlite3 dream runtime tyxml)
 (preprocess (pps lwt_ppx ppx_yojson_conv tyxml-jsx tyxml-ppx)))
|}

let base_dockerfile = {|FROM ubuntu:focal-20210416
RUN apt update && apt install -y openssl libev4 libsqlite3-0
WORKDIR /www
COPY db.sqlite db.sqlite
RUN chmod -R 777 .
USER 112:3000
ENTRYPOINT /www/server.exe
|}

let base_dockerignore = {|*
!db.sqlite|}

let sandbox_dockerfile = {|FROM base:base
COPY server.exe server.exe
|}

let exec format =
  Printf.ksprintf (fun command -> Lwt_process.(exec (shell command))) format

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

let create_named sandbox syntax eml code =
  Dream.info (fun log -> log "Sandbox %s: creating" sandbox);
  begin match%lwt Lwt_unix.mkdir (sandbox_root // sandbox) 0o755 with
  | () -> Lwt.return_unit
  | exception Unix.(Unix_error (EEXIST, _, _)) -> Lwt.return_unit
  end;%lwt
  let filename =
    match syntax, eml with
    | `OCaml, false -> "server.ml"
    | `Reason, false -> "server.re"
    | `OCaml, true -> "server.eml.ml"
    | `Reason, true -> "server.eml.re"
  in
  write_file sandbox filename code;%lwt
  Lwt.return sandbox

let rec create ?(attempts = 3) syntax eml code =
  match attempts with
  | 0 -> failwith "Unable to create sandbox directory"
  | attempts ->
    let sandbox = Dream.random 9 |> Dream.to_base64url in
    match sandbox.[0] with
    | '_' | '-' -> create ~attempts syntax eml code
    | _ ->
      match%lwt exists sandbox with
      | true -> create ~attempts:(attempts - 1) syntax eml code
      | false -> create_named sandbox syntax eml code

let read sandbox =
  let%lwt no_eml_exists =
    Lwt_unix.file_exists (sandbox_root // sandbox // "no-eml") in
  let eml = not no_eml_exists in
  let base = if eml then "server.eml" else "server" in
  let ocaml_promise =
    Lwt_io.(with_file
      ~mode:Input (sandbox_root // sandbox // base ^ ".ml") read)
  in
  match%lwt ocaml_promise with
  | content -> Lwt.return (content, `OCaml, eml)
  | exception _ ->
    let%lwt content =
      Lwt_io.(with_file
        ~mode:Input (sandbox_root // sandbox // base ^ ".re") read)
    in
    Lwt.return (content, `Reason, eml)

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
  eml : bool;
  socket : Dream.websocket;
}

let allocated_ports =
  Hashtbl.create 1024

let kill_container session =
  match session.container with
  | None -> Lwt.return_unit
  | Some {container_id; port} ->
    session.container <- None;
    Dream.info (fun log ->
      log "Sandbox %s: killing container %s" session.sandbox container_id);
    let%lwt _status =
      exec "docker kill %s > /dev/null 2> /dev/null" container_id in
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

let build_sandbox sandbox syntax eml =
  let dune =
    match syntax, eml with
    | _, false -> sandbox_dune_no_eml
    | `OCaml, true -> sandbox_dune
    | `Reason, true -> sandbox_dune_re
  in
  write_file sandbox "dune" dune;%lwt
  begin
    if eml then
      Lwt.return_unit
    else
      write_file sandbox "no-eml" ""
  end;%lwt
  let%lwt _status = exec "rm -f %s/server.exe" (sandbox_root // sandbox) in
  let process =
    Printf.sprintf
      "cd %s && opam exec %s -- dune build %s ./server.exe 2>&1"
      (sandbox_root // sandbox) "--color=always" "--no-print-directory"
    |> Lwt_process.shell
    |> new Lwt_process.process_in in
  let%lwt output = Lwt_io.read process#stdout in
  match%lwt process#close with
  | Unix.WEXITED 0 ->
    let%lwt _status =
      exec
        "cp ../../_build/default/example/z-playground/%s/server.exe %s"
        (sandbox_root // sandbox) (sandbox_root // sandbox)
    in
    Lwt.return None
  | _ ->
    Lwt.return (Some output)

let build session =
  match%lwt build_sandbox session.sandbox session.syntax session.eml with
  | None ->
    Dream.info (fun log -> log "Sandbox %s: build succeeded" session.sandbox);
    Lwt.return_true
  | Some output ->
    Dream.info (fun log ->
      log "Sandbox %s: sending build output" session.sandbox);
    client_log session output;%lwt
    Lwt.return_false

let image_exists sandbox =
  match%lwt exec "docker image inspect sandbox:%s 2>&1 > /dev/null" sandbox with
  | Unix.WEXITED 0 -> Lwt.return_true
  | _ -> Lwt.return_false

let image_sandbox sandbox =
  write_file sandbox "Dockerfile" sandbox_dockerfile;%lwt
  let%lwt _status =
    exec "cd %s && docker build -t sandbox:%s . 2>&1"
      (sandbox_root // sandbox) sandbox in
  Lwt.return_unit

let image session =
  image_sandbox session.sandbox;%lwt
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

let gc_running =
  ref None

let notify_gc =
  ref ignore

let sandbox_users =
  ref 0

let sandbox_locks =
  Hashtbl.create 256

let lock_sandbox sandbox f =
  begin match !gc_running with
  | None -> Lwt.return_unit
  | Some finished -> finished
  end;%lwt

  incr sandbox_users;
  let mutex =
    match Hashtbl.find_opt sandbox_locks sandbox with
    | Some mutex -> mutex
    | None ->
      let mutex = Lwt_mutex.create () in
      Hashtbl.add sandbox_locks sandbox mutex;
      mutex
  in
  Lwt.finalize
    (fun () -> Lwt_mutex.with_lock mutex f)
    (fun () ->
      decr sandbox_users;
      if !sandbox_users = 0 then
        !notify_gc ();
      Lwt.return_unit)

let rec listen session =
  match%lwt Dream.receive session.socket with
  | None ->
    Dream.info (fun log -> log "WebSocket closed by client");
    kill session
  | Some code ->

  Dream.info (fun log -> log "Sandbox %s: code update" session.sandbox);
  ignore (kill_container session);

  lock_sandbox session.sandbox begin fun () ->

    let%lwt current_code, _, _ = read session.sandbox in
    if code = current_code then
      Lwt.return_unit
    else begin
      let%lwt sandbox = create session.syntax session.eml code in
      session.sandbox <- sandbox;
      Lwt.return_unit
    end;%lwt

    match%lwt image_exists session.sandbox with
    | true -> run session
    | false ->
      match%lwt build session with
      | false -> Lwt.return_unit
      | true ->
        image session;%lwt
        run session
  end;%lwt

  listen session

let listen session =
  try%lwt
    listen session
  with exn ->
    kill session;%lwt
    raise exn



let rec gc ?(initial = true) () =
  let next = Lwt_unix.sleep 3600. in

  let%lwt keep =
    Lwt_process.shell "ls sandbox/*/keep | awk -F / '{print $2}'"
    |> Lwt_process.pread_lines
    |> Lwt_stream.to_list in

  let can_start, signal_can_start = Lwt.wait () in
  let finished, signal_finished = Lwt.wait () in

  gc_running := Some finished;

  if !sandbox_users = 0 then
    Lwt.return_unit
  else begin
    notify_gc :=
      (fun () -> Lwt.wakeup_later signal_can_start (); notify_gc := ignore);
    can_start
  end;%lwt

  Lwt.finalize begin fun () ->
    Dream.log "Running playground GC";

    let%lwt images =
      Lwt_process.shell "docker images | awk '{print $1, $2, $3}'"
      |> Lwt_process.pread_lines
      |> Lwt_stream.to_list
    in

    let images =
      images
      |> List.tl
      |> List.map (String.split_on_char ' ')
      |> List.filter_map (function
        | ["base"; _; _] -> None
        | ["ubuntu"; _; ] -> None
        | ["sandbox"; tag; _] when List.mem tag keep -> None
        | [_; _; id] -> Some id
        | _ -> None)
    in

    let%lwt _status = exec "docker rmi %s" (String.concat " " images) in

    Lwt_unix.files_of_directory "sandbox"
    |> Lwt_stream.iter_n ~max_concurrency:16 begin fun sandbox ->
      if List.mem sandbox keep then
        Lwt.return_unit
      else
        let%lwt _status = exec "rm -rf sandbox/%s/_build" sandbox in
        Lwt.return_unit
    end;%lwt

    Hashtbl.reset sandbox_locks;

    Lwt.return_unit
  end
    (fun () ->
      gc_running := None;
      Lwt.wakeup_later signal_finished ();
      Lwt.return_unit);%lwt

  Dream.log "Warming caches";

  keep |> Lwt_list.iteri_s begin fun index sandbox ->
    Lwt_unix.sleep 1.;%lwt
    if initial then
      Dream.log "Warming %s (%i/%i)" sandbox (index + 1) (List.length keep);
    lock_sandbox sandbox (fun () ->
      if%lwt image_exists sandbox then
        Lwt.return_unit
      else begin
        let%lwt _, syntax, eml = read sandbox in
        let%lwt _ = build_sandbox sandbox syntax eml in
        image_sandbox sandbox
      end)
  end;%lwt

  next;%lwt
  gc ~initial:false ()



(* Entry point. *)

let () =
  Dream.log "Starting playground";

  (* Stop when systemd sends SIGTERM. *)
  let stop, signal_stop = Lwt.wait () in
  Lwt_unix.on_signal Sys.sigterm (fun _signal ->
    Lwt.wakeup_later signal_stop ())
  |> ignore;

  (* Build the base image. *)
  Lwt_main.run begin
    Lwt_io.(with_file ~mode:Output "Dockerfile" (fun channel ->
      write channel base_dockerfile));%lwt
    Lwt_io.(with_file ~mode:Output ".dockerignore" (fun channel ->
      write channel base_dockerignore));%lwt
    let%lwt _status = exec "docker build -t base:base . 2>&1" in
    Lwt.return_unit
  end;

  (* Start the sandbox gc. *)
  Lwt.async gc;

  (* Start the Web server. *)
  let playground_handler request =
    let sandbox = Dream.param request "id" in
    match validate_id sandbox with
    | false -> Dream.empty `Not_Found
    | true ->
    match%lwt exists sandbox with
    | false -> Dream.empty `Not_Found
    | true ->
    let%lwt example =
      match sandbox.[1] with
      | '-' ->
        if%lwt Lwt_unix.file_exists (sandbox_root // sandbox // "keep") then
          Lwt.return (Some sandbox)
        else
          Lwt.return_none
      | _ -> Lwt.return_none
      | exception _ -> Lwt.return_none
    in
    Dream.html (Client.html example)
  in

  Dream.run ~interface:"0.0.0.0" ~port:80 ~stop ~adjust_terminal:false
  @@ Dream.logger
  @@ Dream.router [

    (* The client will send a default sandbox id in this case. *)
    Dream.get "/" (fun _ ->
      Dream.html (Client.html None));

    (* Upon request for /socket?sandbox=id, send the code in the sandbox to the
       client, and then enter the "REPL." Not bothering with nice replies or
       nice error handling here, because a valid client won't trigger them. If
       they occur, they are harmless to the server. *)
    Dream.get "/socket" (fun request ->
      match Dream.query request "sandbox" with
      | None -> Dream.empty `Bad_Request
      | Some sandbox ->
      match validate_id sandbox with
      | false -> Dream.empty `Bad_Request
      | true ->
      (* Read the sandbox. If the requested sandbox doesn't exist, this will
         raise an exception, causing a 500 reply to the JavaScript client. *)
      let%lwt content, syntax, eml = read sandbox in
      Dream.websocket (fun socket ->
        init_client socket content;%lwt
        Dream.info (fun log ->
          log "Sandbox %s: content sent to client" sandbox);
        listen {container = None; sandbox; syntax; eml; socket}));

    (* Serve scripts and CSS. *)
    Dream.get "/static/**" (Dream.static "./static");

    (* For sandbox ids, respond with the sandbox page. *)
    Dream.get "/:id" playground_handler;
    Dream.get "/:id/**" playground_handler;

  ];

  Dream.log "Killing all containers";
  Sys.command "docker kill $(docker ps -q)" |> ignore;
  Dream.log "Exiting"
