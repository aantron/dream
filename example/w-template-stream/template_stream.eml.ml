let render response =
  %% response
  <html>
  <body>

%   let rec paragraphs index =
      <p><%i index %></p>
%     let%lwt () = Dream.flush response in
%     let%lwt () = Lwt_unix.sleep 1. in
%     paragraphs (index + 1)
%   in
%   let%lwt () = paragraphs 0 in
(*   let () = *)
(*     %% response *)
(*     <html> *)
(*     <body> *)

(* %     let rec paragraphs index = *)
(*         <p><%i index %></p> *)
(* %       Dream.flush response; *)
(* %       Eio_unix.sleep 1.; *)
(* %       if index < 10 then paragraphs (index + 1) *)
(* %     in *)
(* %     paragraphs 0; *)

(* let render ~clock response = *)
(*   let () = *)
(*     %% response *)
(*     <html> *)
(*     <body> *)

(* %     let rec paragraphs index = *)
(*         <p><%i index %></p> *)
(* %       Dream.flush response; *)
(* %       Eio.Time.sleep clock 1.; *)
(* %       if index < 10 then paragraphs (index + 1) *)
(* %     in *)
(* %     paragraphs 0; *)

  </body>
  </html>

let () =
  Eio_main.run @@ fun env ->
  Dream.run env
  @@ Dream.logger
  @@ fun request -> Dream.stream ~headers:["Content-Type", Dream.text_html] request render
