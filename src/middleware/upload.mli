module Dream = Dream__pure.Inmost

val upload : Dream.request -> Dream.upload_event Dream.promise
val upload_part : Dream.request -> string option Dream.promise

type part = { headers : (string * string) list; filename : string option; contents : string; }

val multipart : Dream.request ->
  [ `Expired of (string * part list) list * float
  | `Invalid_token of (string * part list) list
  | `Many_tokens of (string * part list) list
  | `Missing_token of (string * part list) list
  | `Ok of (string * part list) list
  | `Wrong_content_type
  | `Wrong_session of (string * part list) list ] Dream.promise
