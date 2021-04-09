open Js_of_ocaml

let () =
  let body = Dom_html.getElementById_exn "body" in
  let p = Dom_html.(createP document) in
  p##.innerHTML := Js.string (Common.greet `Client);
  Dom.appendChild body p
