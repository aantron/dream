(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Formats = Dream_pure.Formats
module Dream = Dream_pure
module Cipher = Dream__cipher.Cipher



let infer_cookie_prefix prefix domain path secure =
  match prefix, domain, path, secure with
    | Some (Some `Host), _, _, _ -> "__Host-"
    | Some (Some `Secure), _, _, _ -> "__Secure-"
    | Some None, _, _, _ -> ""
    | None, None, Some "/", true -> "__Host-"
    | None, _, _, true -> "__Secure-"
    | None, _, _, _ -> ""

(* TODO Some actual performance in the implementation. *)
let cookie
    ?prefix:cookie_prefix
    ?decrypt:(decrypt_cookie = true)
    ?domain
    ?path
    ?secure
    name
    request =

  let path =
    match path with
    | Some path -> path
    | None -> Some (Dream.prefix request)
  in

  let secure =
    match secure with
    | Some secure -> secure
    | None -> Dream.https request
  in

  let cookie_prefix = infer_cookie_prefix cookie_prefix domain path secure in
  let name = cookie_prefix ^ name in
  let test = fun (name', _) -> name = name' in

  match Dream.all_cookies request |> List.find_opt test with
  | None -> None
  | Some (_, value) ->
    if not decrypt_cookie then
      Some value
    else
      match Formats.from_base64url value with
      | None ->
        None
      | Some value ->
        Cipher.decrypt request value ~associated_data:("dream.cookie-" ^ name)

let set_cookie
    ?prefix:cookie_prefix
    ?encrypt:(encrypt_cookie = true)
    ?expires
    ?max_age
    ?domain
    ?path
    ?secure
    ?(http_only = true)
    ?same_site
    name
    value
    request
    response =

  (* TODO Need the site prefix, not the subsite prefix! *)
  let path =
    match path with
    | Some path -> path
    | None -> Some (Dream.prefix request)
  in

  let secure =
    match secure with
    | Some secure -> secure
    | None -> Dream.https request
  in

  let cookie_prefix = infer_cookie_prefix cookie_prefix domain path secure in

  let same_site =
    match same_site with
    | None -> Some `Strict
    | Some None -> None
    | Some (Some `Strict) -> Some `Strict
    | Some (Some `Lax) -> Some `Lax
    | Some (Some `None) -> Some `None
  in

  let name = cookie_prefix ^ name in

  let value =
    if encrypt_cookie then
      (* Give each cookie name a different associated data "space," effectively
         partitioning valid ciphertexts among the cookies. See also
         https://github.com/aantron/dream/issues/19#issuecomment-820250853. *)
      Cipher.encrypt request value ~associated_data:("dream.cookie-" ^ name)
      |> Formats.to_base64url
    else
      value
  in

  let set_cookie =
    Formats.to_set_cookie
      ?expires ?max_age ?domain ?path ~secure ~http_only ?same_site name value
  in

  Dream.add_header "Set-Cookie" set_cookie response

let drop_cookie
    ?prefix ?domain ?path ?secure ?http_only ?same_site name request response =
  set_cookie
    ?prefix ~encrypt:false ~expires:0. ?domain ?path ?secure ?http_only
    ?same_site name "" request response
