(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Stream = Dream__pure.Stream



let read_and_dump stream =
  Stream.read stream
    ~data:(fun buffer offset length ->
      print_string "read: data: ";
      Bigstringaf.substring buffer ~off:offset ~len:length
      |> print_endline)
    ~close:(fun () ->
      print_endline "read: close")
    ~flush:(fun () ->
      print_endline "read: flush")

let flush_and_dump stream =
  Stream.flush stream
    ~ok:(fun () ->
      print_endline "flush: ok")
    ~close:(fun () ->
      print_endline "flush: close")

let write_and_dump stream buffer offset length =
  Stream.write stream buffer offset length
    ~ok:(fun () ->
      print_endline "write: ok")
    ~close:(fun () ->
      print_endline "write: close")



(* Read-only streams. *)

let%expect_test _ =
  let stream = Stream.empty in
  read_and_dump stream;
  read_and_dump stream;
  Stream.close stream;
  read_and_dump stream;
  [%expect {|
    read: close
    read: close
    read: close |}]

let%expect_test _ =
  let stream = Stream.empty in
  Stream.close stream;
  read_and_dump stream;
  [%expect {| read: close |}]

let%expect_test _ =
  let stream = Stream.string "foo" in
  read_and_dump stream;
  read_and_dump stream;
  read_and_dump stream;
  Stream.close stream;
  read_and_dump stream;
  [%expect {|
    read: data: foo
    read: close
    read: close
    read: close |}]

let%expect_test _ =
  let stream = Stream.string "" in
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    read: close
    read: close |}]

let%expect_test _ =
  let stream = Stream.string "foo" in
  Stream.close stream;
  read_and_dump stream;
  [%expect {| read: close |}]

let%expect_test _ =
  let stream = Stream.empty in
  (try write_and_dump stream Bigstringaf.empty 0 0
  with Failure _ as exn -> print_endline (Printexc.to_string exn));
  (try flush_and_dump stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn));
  [%expect {|
    (Failure "write to a read-only stream")
    (Failure "flush of a read-only stream") |}]



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
  Stream.close stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  print_endline "checkpoint 3";
  Stream.close stream;
  [%expect {|
    checkpoint 1
    read: close
    checkpoint 2
    read: close
    checkpoint 3 |}]

let%expect_test _ =
  let stream = Stream.pipe () in
  Stream.close stream;
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    read: close
    read: close |}]



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
  write_and_dump stream buffer 0 3;
  write_and_dump stream buffer 1 1;
  print_endline "checkpoint 2";
  read_and_dump stream;
  write_and_dump stream buffer 0 3;
  try write_and_dump stream buffer 0 3
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    read: data: foo
    write: ok
    checkpoint 2
    read: data: o
    write: ok
    (Failure "stream write: the previous write has not completed") |}]



(* Pipe: interactions between flush and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  flush_and_dump stream;
  Stream.close stream;
  flush_and_dump stream;
  [%expect {|
    flush: close
    flush: close |}]



(* Pipe: interactions between write and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  write_and_dump stream buffer 0 3;
  Stream.close stream;
  write_and_dump stream buffer 0 3;
  [%expect {|
    write: close
    write: close |}]
