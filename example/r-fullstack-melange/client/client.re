open Webapi.Dom;

let () = {
  let body = document |> Document.querySelector("body");

  switch (body) {
  | None => ()
  | Some(body) =>

    let text = Common.greet(`Client);

    let p = document |> Document.createElement("p");
    Element.setInnerText(p, text);
    body |> Element.appendChild(p);
  }
};
