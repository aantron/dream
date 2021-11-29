(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Stream = Dream__pure.Stream



let read_and_dump stream =
  Stream.read stream
    ~data:(fun buffer offset length binary fin ->
      Printf.printf "read: data: BINARY=%b FIN=%b %s\n"
        binary fin (Bigstringaf.substring buffer ~off:offset ~len:length))
    ~close:(fun code ->
      Printf.printf "read: close: CODE=%i\n" code)
    ~flush:(fun () ->
      print_endline "read: flush")
    ~ping:(fun buffer offset length ->
      Printf.printf "read: ping: %s\n"
        (Bigstringaf.substring buffer ~off:offset ~len:length))
    ~pong:(fun buffer offset length ->
      Printf.printf "read: pong: %s\n"
        (Bigstringaf.substring buffer ~off:offset ~len:length))

let flush_and_dump stream =
  Stream.flush stream
    ~ok:(fun () ->
      print_endline "flush: ok")
    ~close:(fun code ->
      Printf.printf "flush: close: CODE=%i\n" code)

let write_and_dump stream buffer offset length binary fin =
  Stream.write stream buffer offset length binary fin
    ~ok:(fun () ->
      print_endline "write: ok")
    ~close:(fun code ->
      Printf.printf "write: close: CODE=%i\n" code)

let ping_and_dump payload stream =
  let length = String.length payload in
  Stream.ping stream (Bigstringaf.of_string ~off:0 ~len:length payload) 0 length
    ~ok:(fun () ->
      print_endline "ping: ok")
    ~close:(fun code ->
      Printf.printf "ping: close: CODE=%i\n" code)

let pong_and_dump payload stream =
  let length = String.length payload in
  Stream.pong stream (Bigstringaf.of_string ~off:0 ~len:length payload) 0 length
    ~ok:(fun () ->
      print_endline "pong: ok")
    ~close:(fun code ->
      Printf.printf "pong: close: CODE=%i\n" code)



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
  let stream = Stream.pipe () in
  read_and_dump stream;
  try read_and_dump stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {| (Failure "stream read: the previous read has not completed") |}]



(* Pipe: interactions between read and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
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
  let stream = Stream.pipe () in
  Stream.close stream 1005;
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    read: close: CODE=1005
    read: close: CODE=1005 |}]



(* Pipe: interactions between read and flush. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  flush_and_dump stream;
  flush_and_dump stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  flush_and_dump stream;
  try flush_and_dump stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    read: flush
    flush: ok
    checkpoint 2
    read: flush
    flush: ok
    (Failure "stream flush: the previous write has not completed") |}]



(* Pipe: interactions between read and write. *)

let buffer =
  Bigstringaf.of_string ~off:0 ~len:3 "foo"

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  write_and_dump stream buffer 0 3 false true;
  write_and_dump stream buffer 1 1 true false;
  print_endline "checkpoint 2";
  read_and_dump stream;
  write_and_dump stream buffer 0 3 true true;
  try write_and_dump stream buffer 0 3 false false
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    read: data: BINARY=false FIN=true foo
    write: ok
    checkpoint 2
    read: data: BINARY=true FIN=false o
    write: ok
    (Failure "stream write: the previous write has not completed") |}]



(* Pipe: interactions between read and ping. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  ping_and_dump "foo" stream;
  ping_and_dump "bar" stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  ping_and_dump "baz" stream;
  try ping_and_dump "quux" stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    read: ping: foo
    ping: ok
    checkpoint 2
    read: ping: bar
    ping: ok
    (Failure "stream ping: the previous write has not completed") |}]



(* Pipe: interactions between read and pong. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  pong_and_dump "foo" stream;
  pong_and_dump "bar" stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  pong_and_dump "baz" stream;
  try pong_and_dump "quux" stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    read: pong: foo
    pong: ok
    checkpoint 2
    read: pong: bar
    pong: ok
    (Failure "stream pong: the previous write has not completed") |}]



(* Pipe: interactions between flush and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  flush_and_dump stream;
  Stream.close stream 1005;
  flush_and_dump stream;
  [%expect {|
    flush: close: CODE=1005
    flush: close: CODE=1005 |}]



(* Pipe: interactions between write and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  write_and_dump stream buffer 0 3 true true;
  Stream.close stream 1005;
  write_and_dump stream buffer 0 3 true false;
  [%expect {|
    write: close: CODE=1005
    write: close: CODE=1005 |}]



(* Pipe: interactions between ping and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  ping_and_dump "foo" stream;
  Stream.close stream 1005;
  ping_and_dump "bar" stream;
  [%expect {|
    ping: close: CODE=1005
    ping: close: CODE=1005 |}]



(* Pipe: interactions between pong and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  pong_and_dump "foo" stream;
  Stream.close stream 1005;
  pong_and_dump "bar" stream;
  [%expect {|
    pong: close: CODE=1005
    pong: close: CODE=1005 |}]
