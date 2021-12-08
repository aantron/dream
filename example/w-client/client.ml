let send () =
  (* TODO Eventually replace this by the higher-level wrappers that Hyper will
     offer. Move the explicit-request call into a proxy example, that forwards
     Dream requests directly to Hyper.send. *)
  (* TODO This example is meant for running concurrently with example/w-echo. *)
  let request =
    Dream.request
      ~method_:`POST
      ~target:"http://127.0.0.1:8080/echo" "Good morning, world!"
      ~headers:["Transfer-Encoding", "chunked"]
  in

  (* TODO Note that this wrapper is not necessary if using, for example,
     Dream.run. Create a proxy example that has both a Dream server and a Hyper
     client, and therefore has no explicit Lwt_main.run. *)
  let done_, notify_done = Lwt.wait () in

  (* TODO Add some kind of primitive error handling, both for network errors
     and for error responses. *)
  let%lwt response = Hyper.send request in

  (* TODO Janky delay to give time for pipelining to intervene. *)
  let%lwt () = Lwt_unix.sleep 5. in

  let rec read () =
    (* TODO Use a higher-level reader once available. *)
    Dream.next
      (Dream.body_stream response)
      ~data:(fun buffer offset length _binary _fin ->
        Bigstringaf.substring buffer ~off:offset ~len:length
        |> print_string;
        read ())
      ~close:(fun _code -> Lwt.wakeup_later notify_done ())
      ~flush:read
      ~ping:(fun _buffer _offset _length -> read ())
      ~pong:(fun _buffer _offset _length -> read ())
  in
  read ();

  done_

let () =
  (* TODO Without Dream.run in the process, this doesn't get set anywhere... *)
  Printexc.record_backtrace true;

  Lwt_main.run begin
    let first = send () in
    let second =
      let%lwt () = Lwt_unix.sleep 1. in
      send ()
    in
    let%lwt () = first in
    let%lwt () = second in
    Lwt.return ()
  end

(* TODO Run the server in the same process. *)
