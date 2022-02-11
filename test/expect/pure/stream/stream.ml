(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Stream = Dream_pure.Stream



let read_and_dump stream =
  Stream.read stream
    ~data:(fun buffer offset length binary fin ->
      Printf.printf "read: data: BINARY=%b FIN=%b %s\n"
        binary fin (Bigstringaf.substring buffer ~off:offset ~len:length))
    ~flush:(fun () ->
      print_endline "read: flush")
    ~ping:(fun buffer offset length ->
      Printf.printf "read: ping: %s\n"
        (Bigstringaf.substring buffer ~off:offset ~len:length))
    ~pong:(fun buffer offset length ->
      Printf.printf "read: pong: %s\n"
        (Bigstringaf.substring buffer ~off:offset ~len:length))
    ~close:(fun code ->
      Printf.printf "read: close: CODE=%i\n" code)
    ~exn:(fun exn ->
      Printf.printf "read: exn: %s\n" (Printexc.to_string exn))

let flush_and_dump stream =
  Stream.flush stream
    ~close:(fun code ->
      Printf.printf "flush: close: CODE=%i\n" code)
    ~exn:(fun exn ->
      Printf.printf "flush: exn: %s\n" (Printexc.to_string exn))
    (fun () ->
      print_endline "flush: ok")

let write_and_dump stream buffer offset length binary fin =
  Stream.write stream buffer offset length binary fin
    ~close:(fun code ->
      Printf.printf "write: close: CODE=%i\n" code)
    ~exn:(fun exn ->
      Printf.printf "write: exn: %s\n" (Printexc.to_string exn))
    (fun () ->
      print_endline "write: ok")

let ping_and_dump payload stream =
  let length = String.length payload in
  Stream.ping stream (Bigstringaf.of_string ~off:0 ~len:length payload) 0 length
    ~close:(fun code ->
      Printf.printf "ping: close: CODE=%i\n" code)
    ~exn:(fun exn ->
      Printf.printf "ping: exn: %s\n" (Printexc.to_string exn))
    (fun () ->
      print_endline "ping: ok")

let pong_and_dump payload stream =
  let length = String.length payload in
  Stream.pong stream (Bigstringaf.of_string ~off:0 ~len:length payload) 0 length
    ~close:(fun code ->
      Printf.printf "pong: close: CODE=%i\n" code)
    ~exn:(fun exn ->
      Printf.printf "pong: exn: %s\n" (Printexc.to_string exn))
    (fun () ->
      print_endline "pong: ok")



(* Read-only streams. *)

let%expect_test _ =
  let stream = Stream.empty in
  read_and_dump stream;
  read_and_dump stream;
  Stream.close stream 1005;
  read_and_dump stream;
  [%expect {|
    read: close: CODE=1000
    read: close: CODE=1000
    read: close: CODE=1000 |}]

let%expect_test _ =
  let stream = Stream.empty in
  Stream.close stream 1005;
  read_and_dump stream;
  [%expect {| read: close: CODE=1000 |}]

let%expect_test _ =
  let stream = Stream.string "foo" in
  read_and_dump stream;
  read_and_dump stream;
  read_and_dump stream;
  Stream.close stream 1005;
  read_and_dump stream;
  [%expect {|
    read: data: BINARY=true FIN=true foo
    read: close: CODE=1000
    read: close: CODE=1000
    read: close: CODE=1000 |}]

let%expect_test _ =
  let stream = Stream.string "" in
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    read: close: CODE=1000
    read: close: CODE=1000 |}]

let%expect_test _ =
  let stream = Stream.string "foo" in
  Stream.close stream 1005;
  read_and_dump stream;
  [%expect {| read: close: CODE=1000 |}]

let%expect_test _ =
  let stream = Stream.empty in
  (try write_and_dump stream Bigstringaf.empty 0 0 false false
  with Failure _ as exn -> print_endline (Printexc.to_string exn));
  (try flush_and_dump stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn));
  (try ping_and_dump "foo" stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn));
  (try pong_and_dump "bar" stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn));
  [%expect {|
    (Failure "write to a read-only stream")
    (Failure "flush of a read-only stream")
    (Failure "ping on a read-only stream")
    (Failure "pong on a read-only stream") |}]



(* Pipe: double read. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  read_and_dump stream;
  try read_and_dump stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {| (Failure "stream read: the previous read has not completed") |}]



(* Pipe: interactions between read and close. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  read_and_dump stream;
  print_endline "checkpoint 1";
  Stream.close stream 1005;
  print_endline "checkpoint 2";
  read_and_dump stream;
  print_endline "checkpoint 3";
  Stream.close stream 1000;
  [%expect {|
    checkpoint 1
    read: close: CODE=1005
    checkpoint 2
    read: close: CODE=1005
    checkpoint 3 |}]

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  Stream.close stream 1005;
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    read: close: CODE=1005
    read: close: CODE=1005 |}]



(* Pipe: interactions between read and flush. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  read_and_dump stream;
  print_endline "checkpoint 1";
  flush_and_dump stream;
  flush_and_dump stream;
  read_and_dump stream;
  [%expect {|
    checkpoint 1
    read: flush
    flush: ok
    read: flush
    flush: ok |}]



(* Pipe: interactions between read and write. *)

let buffer =
  Bigstringaf.of_string ~off:0 ~len:3 "foo"

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  read_and_dump stream;
  print_endline "checkpoint 1";
  write_and_dump stream buffer 0 3 false true;
  write_and_dump stream buffer 1 1 true false;
  read_and_dump stream;
  [%expect {|
    checkpoint 1
    read: data: BINARY=false FIN=true foo
    write: ok
    read: data: BINARY=true FIN=false o
    write: ok |}]



(* Pipe: interactions between read and ping. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  read_and_dump stream;
  print_endline "checkpoint 1";
  ping_and_dump "foo" stream;
  ping_and_dump "bar" stream;
  read_and_dump stream;
  [%expect {|
    checkpoint 1
    read: ping: foo
    ping: ok
    read: ping: bar
    ping: ok |}]



(* Pipe: interactions between read and pong. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  read_and_dump stream;
  print_endline "checkpoint 1";
  pong_and_dump "foo" stream;
  pong_and_dump "bar" stream;
  read_and_dump stream;
  [%expect {|
    checkpoint 1
    read: pong: foo
    pong: ok
    read: pong: bar
    pong: ok |}]



(* Pipe: interactions between flush and close. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  Stream.close stream 1005;
  flush_and_dump stream;
  [%expect {|
    flush: close: CODE=1005 |}]



(* Pipe: interactions between write and close. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  Stream.close stream 1005;
  write_and_dump stream buffer 0 3 true false;
  [%expect {|
    write: close: CODE=1005 |}]



(* Pipe: interactions between ping and close. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  Stream.close stream 1005;
  ping_and_dump "bar" stream;
  [%expect {|
    ping: close: CODE=1005 |}]



(* Pipe: interactions between pong and close. *)

let%expect_test _ =
  let reader, writer = Stream.pipe () in
  let stream = Stream.stream reader writer in
  Stream.close stream 1005;
  pong_and_dump "bar" stream;
  [%expect {|
    pong: close: CODE=1005 |}]
