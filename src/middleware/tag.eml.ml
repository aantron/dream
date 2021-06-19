(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream =
struct
  include Dream__pure.Formats
  include Dream__pure.Method
end

(* TODO Include the path prefix. *)
let form_tag
    ?(method_ = `POST) ?target ?enctype ?(csrf_token = true) ~action request =

  let target =
    match target with
    | Some target -> " target=\"" ^ Dream.html_escape target ^ "\""
    | None -> ""
  in
  let enctype =
    match enctype with
    | Some _ -> " enctype=\"multipart/form-data\""
    | None -> ""
  in
  <form
    method="<%s! Dream.method_to_string method_ %>"
    action="<%s action %>"<%s! target %><%s! enctype %>>
% if csrf_token then begin
%   let token = Csrf.csrf_token request in
    <input name="<%s! Csrf.field_name %>" type="hidden" value="<%s! token %>">
% end;
