(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let html_escape s =
  let buffer = Buffer.create (String.length s * 2) in
  s |> String.iter begin function
    | '&' -> Buffer.add_string buffer "&amp;"
    | '<' -> Buffer.add_string buffer "&lt;"
    | '>' -> Buffer.add_string buffer "&gt;"
    | '"' -> Buffer.add_string buffer "&quot;"
    | '\'' -> Buffer.add_string buffer "&#x27;"
    | c -> Buffer.add_char buffer c
    end;
  Buffer.contents buffer



let to_base64url string =
  Base64.encode_string ~pad:false ~alphabet:Base64.uri_safe_alphabet string

let from_base64url string =
  match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet string with
  | Error _ -> None
  | Ok result -> Some result



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

let to_set_cookie
    ?expires ?max_age ?domain ?path ?secure ?http_only ?same_site name value =

  let expires =
    match Option.bind expires Ptime.of_float_s with
    | None -> ""
    | Some time ->
      let weekday =
        match Ptime.weekday time with
        | `Sun -> "Sun" | `Mon -> "Mon" | `Tue -> "Tue" | `Wed -> "Wed"
        | `Thu -> "Thu" | `Fri -> "Fri" | `Sat -> "Sat"
      in
      let ((y, m, d), ((hh, mm, ss), _tz_offset_s)) = Ptime.to_date_time time in
      let month =
        match m with
        | 1 -> "Jan" | 2 -> "Feb" | 3 -> "Mar" | 4 -> "Apr" | 5 -> "May"
        | 6 -> "Jun" | 7 -> "Jul" | 8 -> "Aug" | 9 -> "Sep" | 10 -> "Oct"
        | 11 -> "Nov" | 12 -> "Dec"
        | _ -> assert false
      in
      (* [Ptime.to_date_time] docs give range 0..60 for [ss], accounting for
         leap seconds. However, RFC 6265 §5.1.1 states:

         5.  Abort these steps and fail to parse the cookie-date if:

           *  the second-value is greater than 59.

           (Note that leap seconds cannot be represented in this syntax.)

         See https://tools.ietf.org/html/rfc6265#section-5.1.1.

         Even though [Ptime.to_date_time] time does not return leap seconds, in
         case I misunderstood the gmtime API, of system differences, or future
         refactoring, make sure no leap seconds creep into the output. *)
      let seconds =
        if ss < 60 then ss else 59 [@coverage off]
      in
      Printf.sprintf "; Expires=%s, %02i %s %i %02i:%02i:%02i GMT"
        weekday d month y hh mm seconds
  in

  let max_age =
    match max_age with
    | None -> ""
    | Some seconds -> Printf.sprintf "; Max-Age=%.0f" (floor seconds)
  in

  let domain =
    match domain with
    | None -> ""
    | Some domain -> Printf.sprintf "; Domain=%s" domain
  in

  let path =
    match path with
    | None -> ""
    | Some path -> Printf.sprintf "; Path=%s" path
  in

  let secure =
    match secure with
    | Some true -> "; Secure"
    | _ -> ""
  in

  let http_only =
    match http_only with
    | Some true -> "; HttpOnly"
    | _ -> ""
  in

  let same_site =
    match same_site with
    | None -> ""
    | Some `Strict -> "; SameSite=Strict"
    | Some `Lax -> "; SameSite=Lax"
    | Some `None -> "; SameSite=None"
  in

  Printf.sprintf "%s=%s%s%s%s%s%s%s%s"
    name value expires max_age domain path secure http_only same_site



let iri_safe_octets =
  String.init 128 (fun i -> Char.chr (i + 128))

let iri_generic =
  `Custom (`Generic, iri_safe_octets, "")

let to_percent_encoded ?(international = true) string =
  let component =
    if international then iri_generic
    else `Generic
  in
  Uri.pct_encode ~component string

let from_percent_encoded string =
  Uri.pct_decode string



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



let split_target string =
  let uri = Uri.of_string string in
  let query =
    match Uri.verbatim_query uri with
    | Some query -> query
    | None -> ""
  in
  Uri.path uri, query

let from_path =
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
let rec drop_trailing_slash = function
  | [] -> []
  | [""] -> []
  | component::components ->
    component::(drop_trailing_slash components)

let to_path ?(relative = false) ?(international = true) components =
  let rec filter_empty_components = function
    | ""::(_::_ as path) -> filter_empty_components path
    | component::path -> component::(filter_empty_components path)
    | [] -> []
  in
  let components = filter_empty_components components in

  let components =
    match relative, components with
    | false, [] -> [""; ""]
    | false, _ -> ""::components
    | true, _ -> components
  in

  components
  |> List.map (to_percent_encoded ~international)
  |> String.concat "/"



let text_html =
  "text/html; charset=utf-8"

let application_json =
  "application/json"
