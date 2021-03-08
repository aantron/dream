type informational = [
  | `Continue
  | `Switching_protocols
]

type success = [
  | `OK
  | `Created
  | `Accepted
  | `Non_authoritative_information
  | `No_content
  | `Reset_content
  | `Partial_content
]

type redirect = [
  | `Multiple_choices
  | `Moved_permanently
  | `Found
  | `See_other
  | `Not_modified
  | `Use_proxy
  | `Temporary_redirect
  | `Permanent_redirect
]

type client_error = [
  | `Bad_request
  | `Unauthorized
  | `Payment_required
  | `Forbidden
  | `Not_found
  | `Method_not_allowed
  | `Not_acceptable
  | `Proxy_authentication_required
  | `Request_timeout
  | `Conflict
  | `Gone
  | `Length_required
  | `Precondition_failed
  | `Payload_too_large
  | `Uri_too_long
  | `Unsupported_media_type
  | `Range_not_satisfiable
  | `Expectation_failed
  | `Misdirected_request
  | `Too_early
  | `Upgrade_required
  | `Precondition_required
  | `Too_many_requests
  | `Request_header_fields_too_large
  | `Unavailable_for_legal_reasons
]

type server_error = [
  | `Internal_server_error
  | `Not_implemented
  | `Bad_gateway
  | `Service_unavailable
  | `Gateway_timeout
  | `Http_version_not_supported
]

type standard_status = [
  | informational
  | success
  | redirect
  | client_error
  | server_error
]

type status = [
  | standard_status
  | `Code of int
]

let is_informational = function
  | #informational -> true
  | `Code code when code >= 100 && code <= 199 -> true
  | _ -> false

let is_success = function
  | #success -> true
  | `Code code when code >= 200 && code <= 299 -> true
  | _ -> false

let is_redirect = function
  | #redirect -> true
  | `Code code when code >= 300 && code <= 399 -> true
  | _ -> false

let is_client_error = function
  | #client_error -> true
  | `Code code when code >= 400 && code <= 499 -> true
  | _ -> false

let is_server_error = function
  | #server_error -> true
  | `Code code when code >= 500 && code <= 599 -> true
  | _ -> false

let status_to_int : status -> int = function
  | `Code code -> code (* TODO Sort last for consistency. *)
  | `Continue -> 100
  | `Switching_protocols -> 101
  | `OK -> 200
  | `Created -> 201
  | `Accepted -> 202
  | `Non_authoritative_information -> 203
  | `No_content -> 204
  | `Reset_content -> 205
  | `Partial_content -> 206
  | `Multiple_choices -> 300
  | `Moved_permanently -> 301
  | `Found -> 302
  | `See_other -> 303
  | `Not_modified -> 304
  | `Use_proxy -> 305
  | `Temporary_redirect -> 307
  | `Permanent_redirect -> 308
  | `Bad_request -> 400
  | `Unauthorized -> 401
  | `Payment_required -> 402
  | `Forbidden -> 403
  | `Not_found -> 404
  | `Method_not_allowed -> 405
  | `Not_acceptable -> 406
  | `Proxy_authentication_required -> 407
  | `Request_timeout -> 408
  | `Conflict -> 409
  | `Gone -> 410
  | `Length_required -> 411
  | `Precondition_failed -> 412
  | `Payload_too_large -> 413
  | `Uri_too_long -> 414
  | `Unsupported_media_type -> 415
  | `Range_not_satisfiable -> 416
  | `Expectation_failed -> 417
  | `Misdirected_request -> 421
  | `Too_early -> 425
  | `Upgrade_required -> 426
  | `Precondition_required -> 428
  | `Too_many_requests -> 429
  | `Request_header_fields_too_large -> 431
  | `Unavailable_for_legal_reasons -> 451
  | `Internal_server_error -> 500
  | `Not_implemented -> 501
  | `Bad_gateway -> 502
  | `Service_unavailable -> 503
  | `Gateway_timeout -> 504
  | `Http_version_not_supported -> 505

let int_to_status : int -> status = function
  | 100 -> `Continue
  | 101 -> `Switching_protocols
  | 200 -> `OK
  | 201 -> `Created
  | 202 -> `Accepted
  | 203 -> `Non_authoritative_information
  | 204 -> `No_content
  | 205 -> `Reset_content
  | 206 -> `Partial_content
  | 300 -> `Multiple_choices
  | 301 -> `Moved_permanently
  | 302 -> `Found
  | 303 -> `See_other
  | 304 -> `Not_modified
  | 305 -> `Use_proxy
  | 307 -> `Temporary_redirect
  | 308 -> `Permanent_redirect
  | 400 -> `Bad_request
  | 401 -> `Unauthorized
  | 402 -> `Payment_required
  | 403 -> `Forbidden
  | 404 -> `Not_found
  | 405 -> `Method_not_allowed
  | 406 -> `Not_acceptable
  | 407 -> `Proxy_authentication_required
  | 408 -> `Request_timeout
  | 409 -> `Conflict
  | 410 -> `Gone
  | 411 -> `Length_required
  | 412 -> `Precondition_failed
  | 413 -> `Payload_too_large
  | 414 -> `Uri_too_long
  | 415 -> `Unsupported_media_type
  | 416 -> `Range_not_satisfiable
  | 417 -> `Expectation_failed
  | 421 -> `Misdirected_request
  | 425 -> `Too_early
  | 426 -> `Upgrade_required
  | 428 -> `Precondition_required
  | 429 -> `Too_many_requests
  | 431 -> `Request_header_fields_too_large
  | 451 -> `Unavailable_for_legal_reasons
  | 500 -> `Internal_server_error
  | 501 -> `Not_implemented
  | 502 -> `Bad_gateway
  | 503 -> `Service_unavailable
  | 504 -> `Gateway_timeout
  | 505 -> `Http_version_not_supported
  | code -> `Code code

let status_to_reason status =
  let status =
    match status with
    | `Code code -> int_to_status code
    | _ -> status
  in
  match status with
  | `Continue -> Some "Continue"
  | `Switching_protocols -> Some "Switching Protocols"
  | `OK -> Some "OK"
  | `Created -> Some "Created"
  | `Accepted -> Some "Accepted"
  | `Non_authoritative_information -> Some "Non-Authoritative Information"
  | `No_content -> Some "No Content"
  | `Reset_content -> Some "Reset Content"
  | `Partial_content -> Some "Partial Content"
  | `Multiple_choices -> Some "Multiple Choices"
  | `Moved_permanently -> Some "Moved Permanently"
  | `Found -> Some "Found"
  | `See_other -> Some "See Other"
  | `Not_modified -> Some "Not Modified"
  | `Use_proxy -> Some "Use Proxy"
  | `Temporary_redirect -> Some "Temporary Redirect"
  | `Permanent_redirect -> Some "Permanent Redirect"
  | `Bad_request -> Some "Bad Request"
  | `Unauthorized -> Some "Unauthorized"
  | `Payment_required -> Some "Payment Required"
  | `Forbidden -> Some "Forbidden"
  | `Not_found -> Some "Not Found"
  | `Method_not_allowed -> Some "Method Not Allowed"
  | `Not_acceptable -> Some "Not Acceptable"
  | `Proxy_authentication_required -> Some "Proxy Authentication Required"
  | `Request_timeout -> Some "Request Timeout"
  | `Conflict -> Some "Conflict"
  | `Gone -> Some "Gone"
  | `Length_required -> Some "Length Required"
  | `Precondition_failed -> Some "Precondition Failed"
  | `Payload_too_large -> Some "Payload Too Large"
  | `Uri_too_long -> Some "URI Too Long"
  | `Unsupported_media_type -> Some "Unsupported Media Type"
  | `Range_not_satisfiable -> Some "Range Not Satisfiable"
  | `Expectation_failed -> Some "Expectation Failed"
  | `Misdirected_request -> Some "Misdirected Request"
  | `Too_early -> Some "Too Early"
  | `Upgrade_required -> Some "Upgrade Required"
  | `Precondition_required -> Some "Precondition Required"
  | `Too_many_requests -> Some "Too Many Requests"
  | `Request_header_fields_too_large -> Some "Request Header Fields Too Large"
  | `Unavailable_for_legal_reasons -> Some "Unavailable For Legal Reasons"
  | `Internal_server_error -> Some "Internal Server Error"
  | `Not_implemented -> Some "Not Implemented"
  | `Bad_gateway -> Some "Bad Gateway"
  | `Service_unavailable -> Some "Service Unavailable"
  | `Gateway_timeout -> Some "Gateway Timeout"
  | `Http_version_not_supported -> Some "HTTP Version Not Supported"
  | `Code 102 -> Some "Processing"
  | `Code 103 -> Some "Early Hints"
  | `Code 207 -> Some "Multi-Status"
  | `Code 208 -> Some "Already Reported"
  | `Code 228 -> Some "IM Used"
  | `Code 306 -> Some "Switch Proxy"
  | `Code 418 -> Some "I'm a teapot"
  | `Code 422 -> Some "Unprocessable Entity"
  | `Code 423 -> Some "Locked"
  | `Code 424 -> Some "Failed Dependency"
  | `Code 506 -> Some "Variant Also Negotiates"
  | `Code 507 -> Some "Insufficient Storage"
  | `Code 508 -> Some "Loop Detected"
  | `Code 510 -> Some "Not Extended"
  | `Code 511 -> Some "Network Authentication Required"
  | `Code _ -> None

let status_to_string status =
  match status_to_reason status, status with
  | Some reason, _ -> reason
  | None, `Code code -> string_of_int code
  | _ -> "Unknown" [@coverage off] (* Should be impossible. *)
