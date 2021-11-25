(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Stream = Dream__pure.Stream



let read_and_dump stream =
  Stream.read stream
    ~data:(fun buffer offset length ->
      print_string "data: ";
      Bigstringaf.substring buffer ~off:offset ~len:length
      |> print_endline)

    ~close:(fun () ->
      print_endline "close")

    ~flush:(fun () ->
      print_endline "flush")

    ~exn:(fun _ ->
      print_endline "exn")



(* Read-only streams. *)

let%expect_test _ =
  let stream = Stream.empty in
  read_and_dump stream;
  read_and_dump stream;
  Stream.close stream;
  read_and_dump stream;
  [%expect {|
    close
    close
    close |}]

let%expect_test _ =
  let stream = Stream.empty in
  Stream.close stream;
  read_and_dump stream;
  [%expect {| close |}]

let%expect_test _ =
  let stream = Stream.string "foo" in
  read_and_dump stream;
  read_and_dump stream;
  read_and_dump stream;
  Stream.close stream;
  read_and_dump stream;
  [%expect {|
    data: foo
    close
    close
    close |}]

let%expect_test _ =
  let stream = Stream.string "" in
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    close
    close |}]

let%expect_test _ =
  let stream = Stream.string "foo" in
  Stream.close stream;
  read_and_dump stream;
  [%expect {| close |}]



(* Pipe: double read. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  try read_and_dump stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {| (Failure "Stream read: the previous read has not completed") |}]



(* Pipe: interactions between read and close. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  (* TODO Check that the callback is called. *)
  Stream.close stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  print_endline "checkpoint 3";
  Stream.close stream;
  [%expect {|
    checkpoint 1
    close
    checkpoint 2
    close
    checkpoint 3 |}]

let%expect_test _ =
  let stream = Stream.pipe () in
  Stream.close stream;
  read_and_dump stream;
  read_and_dump stream;
  [%expect {|
    close
    close |}]



(* Pipe: interactions between read and flush. *)

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  (* TODO Check the callbacks are called. *)
  Stream.flush ignore ignore ignore stream;
  Stream.flush ignore ignore ignore stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  Stream.flush ignore ignore ignore stream;
  try Stream.flush ignore ignore ignore stream
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    flush
    checkpoint 2
    flush
    (Failure "Stream flush: the previous write has not completed") |}]



(* Pipe: interactions between read and write. *)

let buffer =
  Bigstringaf.of_string ~off:0 ~len:3 "foo"

let%expect_test _ =
  let stream = Stream.pipe () in
  read_and_dump stream;
  print_endline "checkpoint 1";
  (* TODO Check the callbacks are called. *)
  Stream.write buffer 0 3 ignore ignore ignore stream;
  Stream.write buffer 1 1 ignore ignore ignore stream;
  print_endline "checkpoint 2";
  read_and_dump stream;
  Stream.write buffer 0 3 ignore ignore ignore stream;
  try Stream.write buffer 0 3 ignore ignore ignore stream;
  with Failure _ as exn -> print_endline (Printexc.to_string exn);
  [%expect {|
    checkpoint 1
    data: foo
    checkpoint 2
    data: o
    (Failure "Stream write: the previous write has not completed") |}]



(* TODO: Test:

- Writing to a read-only stream. Flushing, etc.
- Early close of read-only streams or any other streams by the reader.
- The generic read_only needs to take a close callback in addition to the
  reader.
- Stream.string needs to be able to abort the string by providing an appropriate
  such callback.
- Have the string stream release the string eagerly after it is read.
- Interactions between writers (including flush) and close. This will benefit
  from clarifying the writers' callbacks.
- The higher-level reading helpers.
*)
