(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* TODO Decide what to do this based on the deprecation (or not) of val path. *)
module Dream =
struct
  include Dream
  let path = path [@ocaml.warning "-3"]
end



let () =
  ignore Initialize.require

let path request =
  Dream.path request
  |> String.concat "/"
  |> fun path -> "/" ^ path



let show_tokens route =
  try
    Dream__server.Router.parse route
    |> List.map (function
      | Dream__server.Router.Literal s -> Printf.sprintf "%S" s
      | Dream__server.Router.Param s -> Printf.sprintf ":%S" s
      | Dream__server.Router.Wildcard s -> Printf.sprintf "*%S" s)
    |> String.concat "; "
    |> Printf.printf "[%s]\n"
  with Failure message ->
    print_endline message

let%expect_test _ =
  show_tokens "";
  show_tokens "abc";
  show_tokens "/";
  show_tokens "/abc";
  show_tokens "/abc/";
  show_tokens "/abc/def/";
  show_tokens "/abc//def/";
  show_tokens "//abc/def/";
  show_tokens "/abc/def//";
  show_tokens "/abc/:def/";
  show_tokens "/abc/:def";
  show_tokens "/:";
  show_tokens "/abc/:";
  show_tokens "/abc/:/";
  show_tokens "/abc/de:f/";
  [%expect {|
    []
    ["abc"]
    [""]
    ["abc"]
    ["abc"; ""]
    ["abc"; "def"; ""]
    ["abc"; "def"; ""]
    ["abc"; "def"; ""]
    ["abc"; "def"; ""]
    ["abc"; :"def"; ""]
    ["abc"; :"def"]
    Empty path parameter name in '/:'
    Empty path parameter name in '/abc/:'
    Empty path parameter name in '/abc/:/'
    ["abc"; "de:f"; ""] |}]

let%expect_test _ =
  show_tokens "/**";
  show_tokens "/abc/**";
  show_tokens "/abc/**/";
  show_tokens "/abc/**/ghi";
  show_tokens "/abc/*def/";
  show_tokens "/abc/*def/ghi";
  show_tokens "/abc/**def/";
  show_tokens "/abc/**def/ghi";
  [%expect {|
    [*"*"]
    ["abc"; *"*"]
    Path wildcard must be last
    Path wildcard must be last
    Path wildcard must be just '**'
    Path wildcard must be just '**'
    Path wildcard must be just '**'
    Path wildcard must be just '**' |}]



let show ?(prefix = "/") ?(method_ = `GET) target router =
  try
    Dream.request ~method_ ~target ""
    |> Dream.test ~prefix router
    |> fun response ->
      let body =
        Dream.client_stream response
        |> Obj.magic (* TODO Needs to be replaced by exposing read_until_close
                             as a function on abstract streams. *)
        |> Dream_pure.Stream.read_until_close
        |> Lwt_main.run
      in
      let status = Dream.status response in
      Printf.printf "Response: %i %s\n"
        (Dream.status_to_int status) (Dream.status_to_string status);
      if body <> "" then
        Printf.printf "%s\n" body
      else
        ()
  with Failure message ->
    print_endline message

(* Basic router tests. *)

let%expect_test _ =
  show "/" @@ Dream.router [];
  [%expect {| Response: 404 Not Found |}]

let%expect_test _ =
  show "/" @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/abc" @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.respond "foo");
  ];
  [%expect {| Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc" @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/abc/" @@ Dream.router [
    Dream.get "/abc/" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/abc" @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "foo");
    Dream.get "/def" (fun _ -> Dream.respond "bar");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/def" @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "foo");
    Dream.get "/def" (fun _ -> Dream.respond "bar");
  ];
  [%expect {|
    Response: 200 OK
    bar |}]

(* Router matches IRIs. *)
let%expect_test _ =
  show "/λ" @@ Dream.router [
    Dream.get "/λ" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

(* Router matches long paths, does not match prefixes, etc. *)

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/def" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/abc" @@ Dream.router [
    Dream.get "/abc/def" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

(* Router distinguishes resources and directories. *)

let%expect_test _ =
  show "/abc" @@ Dream.router [
    Dream.get "/abc/" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc/" @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

(* Router respects methods. *)

let%expect_test _ =
  show ~method_:`POST "/abc" @@ Dream.router [
    Dream.post "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:(`Method "POST") "/abc" @@ Dream.router [
    Dream.post "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`POST "/abc" @@ Dream.router [
    Dream.get "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc" @@ Dream.router [
    Dream.post "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

(* Briefly test all the other methods. *)

let%expect_test _ =
  show ~method_:`PUT "/abc" @@ Dream.router [
    Dream.put "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`DELETE "/abc" @@ Dream.router [
    Dream.delete "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`HEAD "/abc" @@ Dream.router [
    Dream.head "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`CONNECT "/abc" @@ Dream.router [
    Dream.connect "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`OPTIONS "/abc" @@ Dream.router [
    Dream.options "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`TRACE "/abc" @@ Dream.router [
    Dream.trace "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~method_:`PATCH "/abc" @@ Dream.router [
    Dream.patch "/abc" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

(* Router matches and sets variables. *)

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/:x" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/abc/" @@ Dream.router [
    Dream.get "/abc/:x" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/:x" (fun request ->
      Dream.respond (Dream.param request "x"));
  ];
  [%expect {|
    Response: 200 OK
    def |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.get "/abc/:x/:y" (fun request ->
      Dream.respond (Dream.param request "x" ^ Dream.param request "y"));
  ];
  [%expect {|
    Response: 200 OK
    defghi |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.get "/abc/:x" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/def" (fun request ->
      Dream.respond (Dream.param request "x"));
  ];
  [%expect {|
    Dream.param: missing path parameter "x" |}]

let%expect_test _ =
  show "/" @@ (fun request ->
    ignore (Dream.param request "x");
    Dream.empty `Not_Found);
  [%expect {| Dream.param: missing path parameter "x" |}]

(* Router respects site prefix. *)

(* TODO These two tests are currently broken due to missing site prefix
   handling while it is rebuilt. *)
(*
let%expect_test _ =
  show ~prefix:"/abc" "/abc/def" @@ Dream.router [
    Dream.get "/def" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show ~prefix:"/abc" "/def" @@ Dream.router [
    Dream.get "/def" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 502 Bad Gateway |}]

let%expect_test _ =
  show ~prefix:"/abc/def" "/abc" @@ Dream.router [
    Dream.get "/def" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 502 Bad Gateway |}]

let%expect_test _ =
  show ~prefix:"/abc/def" "/abc/def/ghi" @@ Dream.router [
    Dream.get "/ghi" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc/def /ghi |}]
*)

(* Direct subsites work. *)

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "/def" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    Response: 200 OK
    / /abc/def |}]

let%expect_test _ =
  show "/def/abc" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "/def" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc/ghi" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "/def" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
    Dream.get "/abc/ghi" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    / /abc/ghi |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.scope "/:x" [] [
      Dream.get "/def" (fun request ->
        Dream.respond (Dream.param request "x"));
    ];
  ];
  [%expect {|
    Response: 200 OK
    abc |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.scope "/:x" [] [
      Dream.get "/:x" (fun request ->
        Dream.respond (Dream.param request "x"));
    ];
  ];
  [%expect {|
    Response: 200 OK
    def |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.scope "/abc" [
      (fun next_handler request -> print_endline "foo"; next_handler request);
      (fun next_handler request -> print_endline "bar"; next_handler request);
    ] [
      Dream.get "/def" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    foo
    bar
    Response: 200 OK
    / /abc/def |}]

let%expect_test _ =
  let pipeline_1 = Dream.pipeline [
    (fun next_handler request -> print_endline "foo"; next_handler request);
    (fun next_handler request -> print_endline "bar"; next_handler request);
  ] in

  let pipeline_2 = Dream.pipeline [
    (fun next_handler request -> print_endline "baz"; next_handler request);
    (fun next_handler request -> print_endline "lel"; next_handler request);
  ] in

  show "/abc/def" @@ Dream.router [
    Dream.scope "/abc" [pipeline_1] [
      Dream.scope "/def" [pipeline_2] [
        Dream.get "" (fun _ -> Dream.respond "wat");
      ];
    ];
  ];
  [%expect {|
    foo
    bar
    baz
    lel
    Response: 200 OK
    wat |}]

(* Router applies middlewares. *)

let%expect_test _ =

  let pipeline = Dream.pipeline [
    (fun next_handler request -> print_endline "foo"; next_handler request);
    (fun next_handler request -> print_endline "bar"; next_handler request);
  ] in

  show "/abc" @@ Dream.router [
    Dream.scope "/" [pipeline] [
      Dream.get "/abc" (fun _ -> Dream.respond "baz");
    ];
  ];
  [%expect {|
    foo
    bar
    Response: 200 OK
    baz |}]

let%expect_test _ =
  show "/" @@ Dream.router [
    Dream.scope "/" [
      (fun next_handler request -> print_endline "foo"; next_handler request);
      (fun next_handler request -> print_endline "bar"; next_handler request);
    ] [
      Dream.get "/abc" (fun _ -> Dream.respond "baz");
    ];
  ];
  [%expect {|
    Response: 404 Not Found |}]

(* Router sequence works. *)

(* let%expect_test _ =
  show "/abc/def" @@ Dream.pipeline [
    Dream.router [
      Dream.get "/abc/ghi" (fun _ -> Dream.respond "first");
    ];
    Dream.router [
      Dream.get "/abc/def" (fun _ -> Dream.respond "second");
    ];
  ];
  [%expect {|
    Response: 200 OK
    second |}] *)

(* Wildcard routes. *)

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc /def |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    / /abc/def |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    / /abc/def |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/def/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {| Response: 404 Not Found |}]

let%expect_test _ =
  show "/abc/def/" @@ Dream.router [
    Dream.get "/abc/def/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc/def / |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.get "/abc/def/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc/def /ghi |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.post "/abc/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {| Response: 404 Not Found |}]

let%expect_test _ =
  show ~method_:`POST "/abc/def" @@ Dream.router [
    Dream.post "/abc/**" (fun request ->
      Dream.respond (Dream.prefix request ^ " " ^ path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc /def |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "/def/**" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    Response: 200 OK
    /abc/def /ghi |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "/**" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    Response: 200 OK
    /abc /def/ghi |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "**" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    Response: 200 OK
    /abc /def/ghi |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.scope "/abc/def" [] [
      Dream.get "**" (fun request ->
        Dream.respond (Dream.prefix request ^ " " ^ path request));
    ];
  ];
  [%expect {|
    Response: 200 OK
    /abc/def /ghi |}]

(* Wildcard works with params. *)

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.get "/:x/**" (fun request ->
      Printf.ksprintf Dream.respond "%s %s %s"
        (Dream.prefix request)
        (Dream.param request "x")
        (path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc abc /def/ghi |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.get "/abc/:x/**" (fun request ->
      Printf.ksprintf Dream.respond "%s %s %s"
        (Dream.prefix request)
        (Dream.param request "x")
        (path request));
  ];
  [%expect {|
    Response: 200 OK
    /abc/def def /ghi |}]

let%expect_test _ =
  show "/abc/def/ghi" @@ Dream.router [
    Dream.scope "/abc" [] [
      Dream.get "/:x/**" (fun request ->
        Printf.ksprintf Dream.respond "%s %s %s"
          (Dream.prefix request)
          (Dream.param request "x")
          (path request));
    ];
  ];
  [%expect {|
    Response: 200 OK
    /abc/def def /ghi |}]

(* Routers can be nested indirectly. *)

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/abc/**" (fun request ->
      request
      |> Dream.router [
        Dream.get "/def" (fun request ->
          Dream.respond (Dream.prefix request ^ " " ^ path request));
      ])
  ];
  [%expect {|
    Response: 200 OK
    /abc /def |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/:x/**" (fun request ->
      request
      |> Dream.router [
        Dream.get "/:y" (fun request ->
          Printf.ksprintf Dream.respond "%s %s %s %s"
            (Dream.prefix request)
            (Dream.param request "x")
            (Dream.param request "y")
            (path request));
      ])
  ];
  [%expect {|
    Response: 200 OK
    /abc abc def /def |}]

let%expect_test _ =
  show "/abc/def" @@ Dream.router [
    Dream.get "/:x/**" (fun request ->
      request
      |> Dream.router [
        Dream.get "/:x" (fun request ->
          Printf.ksprintf Dream.respond "%s %s %s"
            (Dream.prefix request)
            (Dream.param request "x")
            (path request));
      ])
  ];
  [%expect {|
    Response: 200 OK
    /abc def /def |}]

(* It's possible to match OPTIONS *. *)

let%expect_test _ =
  show ~method_:`OPTIONS "*" @@ Dream.router [
    Dream.options "*" (fun _ -> Dream.respond "matched");
  ];
  [%expect {|
    Response: 200 OK
    matched |}]

(* no_route. *)

let%expect_test _ =
  show "/" @@ Dream.router [
    Dream.no_route;
  ];
  [%expect {| Response: 404 Not Found |}]

let%expect_test _ =
  show "/" @@ Dream.router [
    Dream.no_route;
    Dream.get "/" (fun _ -> Dream.respond "foo");
  ];
  [%expect {|
    Response: 200 OK
    foo |}]

let%expect_test _ =
  show "/" @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.respond "foo");
    Dream.no_route;
  ];
  [%expect {|
    Response: 200 OK
    foo |}]
