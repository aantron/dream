let or_none f value =
  match f value with
  Some string -> string
  | None -> "None"



let show_status status =
  Printf.printf "%i %5b %5b %5b %5b %5b\n     %s\n     %s\n"
    (Dream.status_to_int status)
    (Dream.is_informational status)
    (Dream.is_success status)
    (Dream.is_redirect status)
    (Dream.is_client_error status)
    (Dream.is_server_error status)
    (or_none Dream.status_to_reason status)
    (Dream.status_to_string status)

let informational = [
  `Continue;
  `Switching_protocols;
]

let%expect_test _ =
  informational |> List.iter show_status;
  [%expect {|
    100  true false false false false
         Continue
         Continue
    101  true false false false false
         Switching Protocols
         Switching Protocols |}]

let success = [
  `OK;
  `Created;
  `Accepted;
  `Non_authoritative_information;
  `No_content;
  `Reset_content;
  `Partial_content;
]

let%expect_test _ =
  success |> List.iter show_status;
  [%expect {|
    200 false  true false false false
         OK
         OK
    201 false  true false false false
         Created
         Created
    202 false  true false false false
         Accepted
         Accepted
    203 false  true false false false
         Non-Authoritative Information
         Non-Authoritative Information
    204 false  true false false false
         No Content
         No Content
    205 false  true false false false
         Reset Content
         Reset Content
    206 false  true false false false
         Partial Content
         Partial Content |}]

let redirect = [
  `Multiple_choices;
  `Moved_permanently;
  `Found;
  `See_other;
  `Not_modified;
  `Use_proxy;
  `Temporary_redirect;
  `Permanent_redirect;
]

let%expect_test _ =
  redirect |> List.iter show_status;
  [%expect {|
    300 false false  true false false
         Multiple Choices
         Multiple Choices
    301 false false  true false false
         Moved Permanently
         Moved Permanently
    302 false false  true false false
         Found
         Found
    303 false false  true false false
         See Other
         See Other
    304 false false  true false false
         Not Modified
         Not Modified
    305 false false  true false false
         Use Proxy
         Use Proxy
    307 false false  true false false
         Temporary Redirect
         Temporary Redirect
    308 false false  true false false
         Permanent Redirect
         Permanent Redirect |}]

let client_error = [
  `Bad_request;
  `Unauthorized;
  `Payment_required;
  `Forbidden;
  `Not_found;
  `Method_not_allowed;
  `Not_acceptable;
  `Proxy_authentication_required;
  `Request_timeout;
  `Conflict;
  `Gone;
  `Length_required;
  `Precondition_failed;
  `Payload_too_large;
  `Uri_too_long;
  `Unsupported_media_type;
  `Range_not_satisfiable;
  `Expectation_failed;
  `Misdirected_request;
  `Too_early;
  `Upgrade_required;
  `Precondition_required;
  `Too_many_requests;
  `Request_header_fields_too_large;
  `Unavailable_for_legal_reasons;
]

let%expect_test _ =
  client_error |> List.iter show_status;
  [%expect {|
    400 false false false  true false
         Bad Request
         Bad Request
    401 false false false  true false
         Unauthorized
         Unauthorized
    402 false false false  true false
         Payment Required
         Payment Required
    403 false false false  true false
         Forbidden
         Forbidden
    404 false false false  true false
         Not Found
         Not Found
    405 false false false  true false
         Method Not Allowed
         Method Not Allowed
    406 false false false  true false
         Not Acceptable
         Not Acceptable
    407 false false false  true false
         Proxy Authentication Required
         Proxy Authentication Required
    408 false false false  true false
         Request Timeout
         Request Timeout
    409 false false false  true false
         Conflict
         Conflict
    410 false false false  true false
         Gone
         Gone
    411 false false false  true false
         Length Required
         Length Required
    412 false false false  true false
         Precondition Failed
         Precondition Failed
    413 false false false  true false
         Payload Too Large
         Payload Too Large
    414 false false false  true false
         URI Too Long
         URI Too Long
    415 false false false  true false
         Unsupported Media Type
         Unsupported Media Type
    416 false false false  true false
         Range Not Satisfiable
         Range Not Satisfiable
    417 false false false  true false
         Expectation Failed
         Expectation Failed
    421 false false false  true false
         Misdirected Request
         Misdirected Request
    425 false false false  true false
         Too Early
         Too Early
    426 false false false  true false
         Upgrade Required
         Upgrade Required
    428 false false false  true false
         Precondition Required
         Precondition Required
    429 false false false  true false
         Too Many Requests
         Too Many Requests
    431 false false false  true false
         Request Header Fields Too Large
         Request Header Fields Too Large
    451 false false false  true false
         Unavailable For Legal Reasons
         Unavailable For Legal Reasons |}]

let server_error = [
  `Internal_server_error;
  `Not_implemented;
  `Bad_gateway;
  `Service_unavailable;
  `Gateway_timeout;
  `Http_version_not_supported;
]

let%expect_test _ =
  server_error |> List.iter show_status;
  [%expect {|
    500 false false false false  true
         Internal Server Error
         Internal Server Error
    501 false false false false  true
         Not Implemented
         Not Implemented
    502 false false false false  true
         Bad Gateway
         Bad Gateway
    503 false false false false  true
         Service Unavailable
         Service Unavailable
    504 false false false false  true
         Gateway Timeout
         Gateway Timeout
    505 false false false false  true
         HTTP Version Not Supported
         HTTP Version Not Supported |}]



let show_status_code code =
  show_status (Dream.int_to_status code)

let%expect_test _ =
  informational |> List.map Dream.status_to_int |> List.iter show_status_code
