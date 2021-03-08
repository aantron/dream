let (-:) name f = Alcotest.test_case name `Quick f



let tests = "request", [


  "client" -: begin fun () ->

    Dream.request ~client:"1.2.3.4:23456" ""
    |> Dream.client
    |> Alcotest.(check string) "client" "1.2.3.4:23456"

  end;


  "with_client" -: begin fun () ->

    Dream.request ""
    |> Dream.with_client "2.3.4.5:34567"
    |> Dream.client
    |> Alcotest.(check string) "client" "2.3.4.5:34567"

  end;


  "with_client immutable" -: begin fun () ->

    let first = Dream.request ~client:"1.2.3.4:23456" "" in
    let last  = Dream.with_client "2.3.4.5:34567" first in

    Alcotest.(check bool) "different" true (last != first);
    Alcotest.(check string) "client" "1.2.3.4:23456" (Dream.client first);

  end;


  "with_client update" -: begin fun () ->

    let first = Dream.request "" in
    let last  = Dream.with_client "1.2.3.4:23456" first in

    Alcotest.(check bool) "last" true (Dream.last first == last);
    Alcotest.(check bool) "last" true (Dream.last last  == last);

    Alcotest.(check bool) "first" true (Dream.first first == first);
    Alcotest.(check bool) "first" true (Dream.first last  == first);

  end;
]
