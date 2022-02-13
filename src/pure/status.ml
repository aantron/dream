(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



type informational = [
  | `Continue
  | `Switching_Protocols
]

type successful = [
  | `OK
  | `Created
  | `Accepted
  | `Non_Authoritative_Information
  | `No_Content
  | `Reset_Content
  | `Partial_Content
]

type redirection = [
  | `Multiple_Choices
  | `Moved_Permanently
  | `Found
  | `See_Other
  | `Not_Modified
  | `Temporary_Redirect
  | `Permanent_Redirect
]

type client_error = [
  | `Bad_Request
  | `Unauthorized
  | `Payment_Required
  | `Forbidden
  | `Not_Found
  | `Method_Not_Allowed
  | `Not_Acceptable
  | `Proxy_Authentication_Required
  | `Request_Timeout
  | `Conflict
  | `Gone
  | `Length_Required
  | `Precondition_Failed
  | `Payload_Too_Large
  | `URI_Too_Long
  | `Unsupported_Media_Type
  | `Range_Not_Satisfiable
  | `Expectation_Failed
  | `Misdirected_Request
  | `Too_Early
  | `Upgrade_Required
  | `Precondition_Required
  | `Too_Many_Requests
  | `Request_Header_Fields_Too_Large
  | `Unavailable_For_Legal_Reasons
]

type server_error = [
  | `Internal_Server_Error
  | `Not_Implemented
  | `Bad_Gateway
  | `Service_Unavailable
  | `Gateway_Timeout
  | `HTTP_Version_Not_Supported
]

type standard_status = [
  | informational
  | successful
  | redirection
  | client_error
  | server_error
]

type status = [
  | standard_status
  | `Status of int
]

let is_informational = function
  | #informational -> true
  | `Status code when code >= 100 && code <= 199 -> true
  | #status -> false

let is_successful = function
  | #successful -> true
  | `Status code when code >= 200 && code <= 299 -> true
  | #status -> false

let is_redirection = function
  | #redirection -> true
  | `Status code when code >= 300 && code <= 399 -> true
  | #status -> false

let is_client_error = function
  | #client_error -> true
  | `Status code when code >= 400 && code <= 499 -> true
  | #status -> false

let is_server_error = function
  | #server_error -> true
  | `Status code when code >= 500 && code <= 599 -> true
  | #status -> false

let status_to_int = function
  | `Continue -> 100
  | `Switching_Protocols -> 101
  | `OK -> 200
  | `Created -> 201
  | `Accepted -> 202
  | `Non_Authoritative_Information -> 203
  | `No_Content -> 204
  | `Reset_Content -> 205
  | `Partial_Content -> 206
  | `Multiple_Choices -> 300
  | `Moved_Permanently -> 301
  | `Found -> 302
  | `See_Other -> 303
  | `Not_Modified -> 304
  | `Temporary_Redirect -> 307
  | `Permanent_Redirect -> 308
  | `Bad_Request -> 400
  | `Unauthorized -> 401
  | `Payment_Required -> 402
  | `Forbidden -> 403
  | `Not_Found -> 404
  | `Method_Not_Allowed -> 405
  | `Not_Acceptable -> 406
  | `Proxy_Authentication_Required -> 407
  | `Request_Timeout -> 408
  | `Conflict -> 409
  | `Gone -> 410
  | `Length_Required -> 411
  | `Precondition_Failed -> 412
  | `Payload_Too_Large -> 413
  | `URI_Too_Long -> 414
  | `Unsupported_Media_Type -> 415
  | `Range_Not_Satisfiable -> 416
  | `Expectation_Failed -> 417
  | `Misdirected_Request -> 421
  | `Too_Early -> 425
  | `Upgrade_Required -> 426
  | `Precondition_Required -> 428
  | `Too_Many_Requests -> 429
  | `Request_Header_Fields_Too_Large -> 431
  | `Unavailable_For_Legal_Reasons -> 451
  | `Internal_Server_Error -> 500
  | `Not_Implemented -> 501
  | `Bad_Gateway -> 502
  | `Service_Unavailable -> 503
  | `Gateway_Timeout -> 504
  | `HTTP_Version_Not_Supported -> 505
  | `Status code -> code

let int_to_status : int -> status = function
  | 100 -> `Continue
  | 101 -> `Switching_Protocols
  | 200 -> `OK
  | 201 -> `Created
  | 202 -> `Accepted
  | 203 -> `Non_Authoritative_Information
  | 204 -> `No_Content
  | 205 -> `Reset_Content
  | 206 -> `Partial_Content
  | 300 -> `Multiple_Choices
  | 301 -> `Moved_Permanently
  | 302 -> `Found
  | 303 -> `See_Other
  | 304 -> `Not_Modified
  | 307 -> `Temporary_Redirect
  | 308 -> `Permanent_Redirect
  | 400 -> `Bad_Request
  | 401 -> `Unauthorized
  | 402 -> `Payment_Required
  | 403 -> `Forbidden
  | 404 -> `Not_Found
  | 405 -> `Method_Not_Allowed
  | 406 -> `Not_Acceptable
  | 407 -> `Proxy_Authentication_Required
  | 408 -> `Request_Timeout
  | 409 -> `Conflict
  | 410 -> `Gone
  | 411 -> `Length_Required
  | 412 -> `Precondition_Failed
  | 413 -> `Payload_Too_Large
  | 414 -> `URI_Too_Long
  | 415 -> `Unsupported_Media_Type
  | 416 -> `Range_Not_Satisfiable
  | 417 -> `Expectation_Failed
  | 421 -> `Misdirected_Request
  | 425 -> `Too_Early
  | 426 -> `Upgrade_Required
  | 428 -> `Precondition_Required
  | 429 -> `Too_Many_Requests
  | 431 -> `Request_Header_Fields_Too_Large
  | 451 -> `Unavailable_For_Legal_Reasons
  | 500 -> `Internal_Server_Error
  | 501 -> `Not_Implemented
  | 502 -> `Bad_Gateway
  | 503 -> `Service_Unavailable
  | 504 -> `Gateway_Timeout
  | 505 -> `HTTP_Version_Not_Supported
  | code -> `Status code

let status_to_reason status =
  let status = (status :> status) in
  let status =
    match status with
    | `Status code -> int_to_status code
    | _ -> status
  in
  match status with
  | `Continue -> Some "Continue"
  | `Switching_Protocols -> Some "Switching Protocols"
  | `OK -> Some "OK"
  | `Created -> Some "Created"
  | `Accepted -> Some "Accepted"
  | `Non_Authoritative_Information -> Some "Non-Authoritative Information"
  | `No_Content -> Some "No Content"
  | `Reset_Content -> Some "Reset Content"
  | `Partial_Content -> Some "Partial Content"
  | `Multiple_Choices -> Some "Multiple Choices"
  | `Moved_Permanently -> Some "Moved Permanently"
  | `Found -> Some "Found"
  | `See_Other -> Some "See Other"
  | `Not_Modified -> Some "Not Modified"
  | `Temporary_Redirect -> Some "Temporary Redirect"
  | `Permanent_Redirect -> Some "Permanent Redirect"
  | `Bad_Request -> Some "Bad Request"
  | `Unauthorized -> Some "Unauthorized"
  | `Payment_Required -> Some "Payment Required"
  | `Forbidden -> Some "Forbidden"
  | `Not_Found -> Some "Not Found"
  | `Method_Not_Allowed -> Some "Method Not Allowed"
  | `Not_Acceptable -> Some "Not Acceptable"
  | `Proxy_Authentication_Required -> Some "Proxy Authentication Required"
  | `Request_Timeout -> Some "Request Timeout"
  | `Conflict -> Some "Conflict"
  | `Gone -> Some "Gone"
  | `Length_Required -> Some "Length Required"
  | `Precondition_Failed -> Some "Precondition Failed"
  | `Payload_Too_Large -> Some "Payload Too Large"
  | `URI_Too_Long -> Some "URI Too Long"
  | `Unsupported_Media_Type -> Some "Unsupported Media Type"
  | `Range_Not_Satisfiable -> Some "Range Not Satisfiable"
  | `Expectation_Failed -> Some "Expectation Failed"
  | `Misdirected_Request -> Some "Misdirected Request"
  | `Too_Early -> Some "Too Early"
  | `Upgrade_Required -> Some "Upgrade Required"
  | `Precondition_Required -> Some "Precondition Required"
  | `Too_Many_Requests -> Some "Too Many Requests"
  | `Request_Header_Fields_Too_Large -> Some "Request Header Fields Too Large"
  | `Unavailable_For_Legal_Reasons -> Some "Unavailable For Legal Reasons"
  | `Internal_Server_Error -> Some "Internal Server Error"
  | `Not_Implemented -> Some "Not Implemented"
  | `Bad_Gateway -> Some "Bad Gateway"
  | `Service_Unavailable -> Some "Service Unavailable"
  | `Gateway_Timeout -> Some "Gateway Timeout"
  | `HTTP_Version_Not_Supported -> Some "HTTP Version Not Supported"
  | `Status 102 -> Some "Processing"
  | `Status 103 -> Some "Early Hints"
  | `Status 207 -> Some "Multi-Status"
  | `Status 208 -> Some "Already Reported"
  | `Status 228 -> Some "IM Used"
  | `Status 305 -> Some "Use Proxy"
  | `Status 306 -> Some "Switch Proxy"
  | `Status 418 -> Some "I'm a teapot"
  | `Status 422 -> Some "Unprocessable Entity"
  | `Status 423 -> Some "Locked"
  | `Status 424 -> Some "Failed Dependency"
  | `Status 506 -> Some "Variant Also Negotiates"
  | `Status 507 -> Some "Insufficient Storage"
  | `Status 508 -> Some "Loop Detected"
  | `Status 510 -> Some "Not Extended"
  | `Status 511 -> Some "Network Authentication Required"
  | `Status _ -> None

let status_to_string status =
  let status = (status :> status) in
  match status_to_reason status, status with
  | Some reason, _ -> reason
  | None, `Status code -> string_of_int code
  | _ -> "Unknown" [@coverage off] (* Should be impossible. *)

let normalize_status status =
  match (status :> status) with
  | `Status code -> int_to_status code
  | status -> status

let status_codes_equal status_1 status_2 =
  normalize_status status_1 = normalize_status status_2
