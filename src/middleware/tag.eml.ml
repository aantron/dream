(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Formats

(* TODO Include the path prefix. *)
let form ?enctype ~action request =
  let enctype =
    match enctype with
    | Some _ -> " enctype=\"multipart/form-data\""
    | None -> ""
  in
  let token = Csrf.csrf_token request in
  <form method="POST" action="<%s action %>"<%s! enctype %>>
  <input name="<%s! Csrf.field_name %>" type="hidden" value="<%s! token %>">
