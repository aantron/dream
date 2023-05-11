(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream =
struct
  include Dream_pure
  include Dream_pure.Formats
end
(* This slightly awkward simulation of the overall Dream module using a
   composition of internal modules is necessary to get all the helpers at the
   right positions expected by the EML templater. *)
module Method = Dream_pure.Method


let csrf_tag ~now request =
  let token = Csrf.csrf_token ~now request in
  <input name="<%s! Csrf.field_name %>" type="hidden" value="<%s! token %>">
