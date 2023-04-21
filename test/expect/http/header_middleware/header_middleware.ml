(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2022 Anton Bachin *)


   (* let%expect_test _ =
    let headers = [ "", "0"; "", ""; "Content-Type", "text/html; charset=utf-8" ] in
    let handler (h: Dream_pure.Message.handler) (req: Dream_pure.Message.request) =
      Lwt.return (h req)
    in
    let response = Dream__http.Header_middleware.drop_empty_headers handler (Dream.request ~headers:headers "") in
    let headers = Dream.all_headers response  in
    
    print_string [%message (headers : (string * string) list)];
    [%expect {| (headers (("Content-Type" "text/html; charset=utf-8") ("Content-Type" "text/plain"))) |}] *)


let%expect_test _ =
let bad_headers = [ "", "x"; "", "1"; "Content-Type", "text/html; charset=utf-8" ] in
let handler _ =
  let%lwt r = Dream.respond ~headers:bad_headers "" in
  (* List.iter (fun (k, v) -> print_endline (k ^ ": " ^ v)) (Dream.all_headers r); *)
  Lwt.return r
in
let print_middleware handler request =
  (* print_endline "heylllo"; *)
  let headers = Dream.all_headers request in
  (* print_int (List.length headers); *)
  List.iter (fun (k, v) -> print_endline (k ^ ": " ^ v)) headers;
  let%lwt response = handler request in
  Lwt.return response
in
let server =
  Dream.pipeline [
    Dream__http.Header_middleware.drop_empty_headers;
    print_middleware;
  ]
  @@ handler
in
ignore (Lwt_main.run (server (Dream.request "")));
[%expect {|
Content-Type: text/html; charset=utf-8
|}]
