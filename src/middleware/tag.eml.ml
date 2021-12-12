(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream =
struct
  include Dream_pure.Formats
  include Dream_pure.Method
end

(* TODO Include the path prefix. *)
let form_tag
    ~now ?method_ ?target ?enctype ?csrf_token ~action request =

  let method_ =
    match method_ with
    | None -> Dream.method_to_string `POST
    | Some method_ -> Dream.method_to_string method_
  in
  let target =
    match target with
    | Some target -> " target=\"" ^ Dream.html_escape target ^ "\""
    | None -> ""
  in
  let enctype =
    match enctype with
    | Some `Multipart_form_data -> " enctype=\"multipart/form-data\""
    | None -> ""
  in
  let csrf_token =
    match csrf_token with
    | None -> true
    | Some csrf_token -> csrf_token
  in
  <form
    method="<%s! method_ %>"
    action="<%s action %>"<%s! target %><%s! enctype %>>
% if csrf_token then begin
%   let token = Csrf.csrf_token ~now request in
    <input name="<%s! Csrf.field_name %>" type="hidden" value="<%s! token %>">
% end;
