(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let to_base64url string =
  Base64.encode_string ~pad:false ~alphabet:Base64.uri_safe_alphabet string

let from_base64url string =
  match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet string with
  | Error (`Msg string) -> Error string
  | Ok _ as ok -> ok



let from_cookie s =
  let pairs =
    s
    |> String.split_on_char ';'
    |> List.map (String.split_on_char '=')
  in

  pairs |> List.fold_left (fun pairs -> function
    | [name; value] -> (String.trim name, String.trim value)::pairs
    | _ -> pairs) []
(* Note: found ocaml-cookie and http-cookie libraries, but they appear to have
   equivalent code for parsing Cookie: headers, so there is no point in using
   them yet, especially as they have stringent OCaml version constraints for
   other parts of their code. *)
(* Note: this parser doesn't actually appear to comply with the RFC strictly. It
   accepts more characters than the spec allows. It doesn't treate DQUOTE
   specially. This might not be important, however, if user agents treat cookies
   as opaque, because then only Dream has to deal with its own cookies. *)



let to_form_urlencoded dictionary =
  dictionary
  |> List.map (fun (name, value) -> name, [value])
  |> Uri.encoded_of_query

let from_form_urlencoded string =
  if string = "" then
    []
  else
    string
    |> Uri.query_of_encoded
    |> List.map (fun (name, values) -> name, String.concat "," values)



let from_target string =
  let uri = Uri.of_string string in
  let query =
    match Uri.verbatim_query uri with
    | Some query -> query
    | None -> ""
  in
  Uri.path uri, query

let from_target_path =
  (* Not tail-recursive. *)
  let rec filter_components = function
    | [] -> []
    | [""] as components -> components
    | ""::components -> filter_components components
    | component::components -> component::(filter_components components)
  in

  fun string ->
    let components =
      if string = "" then
        []
      else
        String.split_on_char '/' string
        |> filter_components
        |> List.map Uri.pct_decode
    in

    components

(* Not tail-recursive. Only called on the site prefix and route fragments during
   app setup. *)
let rec drop_empty_trailing_path_component = function
  | [] -> []
  | [""] -> []
  | component::components ->
    component::(drop_empty_trailing_path_component components)

(* TODO Currently used mainly for debugging; needs to be replaced by an escaping
   function. *)
let make_path path =
  "/" ^ (String.concat "/" path)
