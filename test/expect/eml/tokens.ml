(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let show input =
  Eml.Location.reset ();

  let underlying = Stream.of_string input in
  let input_stream = Eml.Location.stream (fun () ->
    try Some (Stream.next underlying)
    with _ -> None) in

  try
    input_stream
    |> Eml.Tokenizer.scan
    |> List.map Eml.Token.show
    |> List.iter print_endline
  with Failure message ->
    print_endline message

let%expect_test _ =
  show "";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show " ";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show " \n ";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show "\n\n";
  [%expect {| (1, 0) Code_block |}]

let%expect_test _ =
  show "let foo =\n  bar\n";
  [%expect {|
    (1, 0) Code_block
    let foo =
      bar |}]

let%expect_test _ =
  show "let foo =\n< bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 0
    Text {|< bar|} |xxx}]

let%expect_test _ =
  show "let foo =\n < bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 1
    Text {| < bar|} |xxx}]

let%expect_test _ =
  show "let foo =\n  < bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  < bar|} |xxx}]

let%expect_test _ =
  show "let foo =\n   < bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 3
    Text {|   < bar|} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n  </html>";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  <html>|}
    Newline
    Text {|  </html>|} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n  plain";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  <html>|}
    Newline
    Text {|  plain|} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n  </html>\nlet bar = ()\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  <html>|}
    Newline
    Text {|  </html>|}
    Newline
    (4, 0) Code_block
    let bar = () |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 5) Embedded () a
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a % %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 5) Embedded () a %
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a %%>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 5) Embedded () a %
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <%= a %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 6) Embedded (=) a
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <% a\nb %>\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 5) Embedded () a
    b
    Text {||}
    Newline |xxx}]

let%expect_test _ =
  show "let foo =\n  <%";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 4) Embedded ()
    Text {||} |xxx}]

let%expect_test _ =
  show "let foo =\n  <%\na %>";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (3, 2) Embedded (
    a)
    Text {||} |xxx}]

let%expect_test _ =
  show "let foo =\n  <% \n a";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  |}
    (2, 5) Embedded ()
     a
    Text {||} |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n\na";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  <html>|}
    Newline
    Text {||}
    Newline
    (4, 0) Code_block
    a |xxx}]

let%expect_test _ =
  show "let foo =\n% abc";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    (2, 1) Embedded ()  abc |xxx}]

let%expect_test _ =
  show "let foo =\n% abc\n";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    (2, 1) Embedded ()  abc |xxx}]

let%expect_test _ =
  show "let foo =\n% abc\n% def";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    (2, 1) Embedded ()  abc

    (3, 1) Embedded ()  def |xxx}]

let%expect_test _ =
  show "let foo =\n  <html>\n% abc\n  </html>";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  <html>|}
    Newline
    (3, 1) Embedded ()  abc

    Text {|  </html>|} |xxx}]

let%expect_test _ =
  show "let foo=\n % bar";
  [%expect {|
    (1, 0) Code_block
    let foo=
     % bar |}]

let%expect_test _ =
  show "let foo=\n  <html>\n % bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo=

    Options , 2
    Text {|  <html>|}
    Newline
    (3, 0) Code_block
     % bar |xxx}]

let%expect_test _ =
  show "let foo\n  <html>\n\n% bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo

    Options , 2
    Text {|  <html>|}
    Newline
    Text {||}
    Newline
    (4, 1) Embedded ()  bar |xxx}]

let%expect_test _ =
  show "let foo\n  <html>\n \n% bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo

    Options , 2
    Text {|  <html>|}
    Newline
    Text {| |}
    Newline
    (4, 1) Embedded ()  bar |xxx}]

let%expect_test _ =
  show "let foo = \n  <html>\nbar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo =

    Options , 2
    Text {|  <html>|}
    Newline
    (3, 0) Code_block
    bar |xxx}]

let%expect_test _ =
  show "let foo\n %% a = b\n bar";
  [%expect {xxx|
    (1, 0) Code_block
    let foo

    Options  a = b, 1
    Text {| bar|} |xxx}]

let%expect_test _ =
  show "let foo\n %% a = b\n bar\n %%\n baz";
  [%expect {xxx|
    (1, 0) Code_block
    let foo

    Options  a = b, 1
    Text {| bar|}
    Newline
    (5, 0) Code_block
     baz |xxx}]

let%expect_test _ =
  show "let foo\n %% a = b\n %%";
  [%expect {|
    (1, 0) Code_block
    let foo

    Options  a = b, 1
    (3, 0) Code_block |}]

let%expect_test _ =
  show "let foo\n %% a = b\n %% c\n";
  [%expect {| Line 2: text following closing '%%' |}]
