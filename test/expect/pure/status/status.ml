(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



let or_none f value =
  match f value with
  Some string -> string
  | None -> "None"



let informational = [
  `Continue;
  `Switching_Protocols;
]

let successful = [
  `OK;
  `Created;
  `Accepted;
  `Non_Authoritative_Information;
  `No_Content;
  `Reset_Content;
  `Partial_Content;
]

let redirection = [
  `Multiple_Choices;
  `Moved_Permanently;
  `Found;
  `See_Other;
  `Not_Modified;
  `Temporary_Redirect;
  `Permanent_Redirect;
]

let client_error = [
  `Bad_Request;
  `Unauthorized;
  `Payment_Required;
  `Forbidden;
  `Not_Found;
  `Method_Not_Allowed;
  `Not_Acceptable;
  `Proxy_Authentication_Required;
  `Request_Timeout;
  `Conflict;
  `Gone;
  `Length_Required;
  `Precondition_Failed;
  `Payload_Too_Large;
  `URI_Too_Long;
  `Unsupported_Media_Type;
  `Range_Not_Satisfiable;
  `Expectation_Failed;
  `Misdirected_Request;
  `Too_Early;
  `Upgrade_Required;
  `Precondition_Required;
  `Too_Many_Requests;
  `Request_Header_Fields_Too_Large;
  `Unavailable_For_Legal_Reasons;
]

let server_error = [
  `Internal_Server_Error;
  `Not_Implemented;
  `Bad_Gateway;
  `Service_Unavailable;
  `Gateway_Timeout;
  `HTTP_Version_Not_Supported;
]



(* Variand codes. *)

let show_status status =
  Printf.printf "%3i %-5b %-5b %-5b %-5b %-5b\n    %s\n    %s\n"
    (Dream.status_to_int status)
    (Dream.is_informational status)
    (Dream.is_successful status)
    (Dream.is_redirection status)
    (Dream.is_client_error status)
    (Dream.is_server_error status)
    (or_none Dream.status_to_reason status)
    (Dream.status_to_string status)

let%expect_test _ =
  informational |> List.iter show_status;
  [%expect {|
    100 true  false false false false
        Continue
        Continue
    101 true  false false false false
        Switching Protocols
        Switching Protocols |}]

let%expect_test _ =
  successful |> List.iter show_status;
  [%expect {|
    200 false true  false false false
        OK
        OK
    201 false true  false false false
        Created
        Created
    202 false true  false false false
        Accepted
        Accepted
    203 false true  false false false
        Non-Authoritative Information
        Non-Authoritative Information
    204 false true  false false false
        No Content
        No Content
    205 false true  false false false
        Reset Content
        Reset Content
    206 false true  false false false
        Partial Content
        Partial Content |}]

let%expect_test _ =
  redirection |> List.iter show_status;
  [%expect {|
    300 false false true  false false
        Multiple Choices
        Multiple Choices
    301 false false true  false false
        Moved Permanently
        Moved Permanently
    302 false false true  false false
        Found
        Found
    303 false false true  false false
        See Other
        See Other
    304 false false true  false false
        Not Modified
        Not Modified
    307 false false true  false false
        Temporary Redirect
        Temporary Redirect
    308 false false true  false false
        Permanent Redirect
        Permanent Redirect |}]

let%expect_test _ =
  client_error |> List.iter show_status;
  [%expect {|
    400 false false false true  false
        Bad Request
        Bad Request
    401 false false false true  false
        Unauthorized
        Unauthorized
    402 false false false true  false
        Payment Required
        Payment Required
    403 false false false true  false
        Forbidden
        Forbidden
    404 false false false true  false
        Not Found
        Not Found
    405 false false false true  false
        Method Not Allowed
        Method Not Allowed
    406 false false false true  false
        Not Acceptable
        Not Acceptable
    407 false false false true  false
        Proxy Authentication Required
        Proxy Authentication Required
    408 false false false true  false
        Request Timeout
        Request Timeout
    409 false false false true  false
        Conflict
        Conflict
    410 false false false true  false
        Gone
        Gone
    411 false false false true  false
        Length Required
        Length Required
    412 false false false true  false
        Precondition Failed
        Precondition Failed
    413 false false false true  false
        Payload Too Large
        Payload Too Large
    414 false false false true  false
        URI Too Long
        URI Too Long
    415 false false false true  false
        Unsupported Media Type
        Unsupported Media Type
    416 false false false true  false
        Range Not Satisfiable
        Range Not Satisfiable
    417 false false false true  false
        Expectation Failed
        Expectation Failed
    421 false false false true  false
        Misdirected Request
        Misdirected Request
    425 false false false true  false
        Too Early
        Too Early
    426 false false false true  false
        Upgrade Required
        Upgrade Required
    428 false false false true  false
        Precondition Required
        Precondition Required
    429 false false false true  false
        Too Many Requests
        Too Many Requests
    431 false false false true  false
        Request Header Fields Too Large
        Request Header Fields Too Large
    451 false false false true  false
        Unavailable For Legal Reasons
        Unavailable For Legal Reasons |}]

let%expect_test _ =
  server_error |> List.iter show_status;
  [%expect {|
    500 false false false false true
        Internal Server Error
        Internal Server Error
    501 false false false false true
        Not Implemented
        Not Implemented
    502 false false false false true
        Bad Gateway
        Bad Gateway
    503 false false false false true
        Service Unavailable
        Service Unavailable
    504 false false false false true
        Gateway Timeout
        Gateway Timeout
    505 false false false false true
        HTTP Version Not Supported
        HTTP Version Not Supported |}]



(* Numeric codes. *)

let show_status_code code =
  let status = `Status code in
  Printf.printf "%3i %-5b %-5b %-5b %-5b %-5b\n    %s\n    %s\n"
    (Dream.status_to_int status)
    (Dream.is_informational status)
    (Dream.is_successful status)
    (Dream.is_redirection status)
    (Dream.is_client_error status)
    (Dream.is_server_error status)
    (or_none Dream.status_to_reason status)
    (Dream.status_to_string status)

let%expect_test _ =
  informational |> List.map Dream.status_to_int |> List.iter show_status_code;
  [%expect {|
    100 true  false false false false
        Continue
        Continue
    101 true  false false false false
        Switching Protocols
        Switching Protocols |}]

let%expect_test _ =
  successful |> List.map Dream.status_to_int |> List.iter show_status_code;
  [%expect {|
    200 false true  false false false
        OK
        OK
    201 false true  false false false
        Created
        Created
    202 false true  false false false
        Accepted
        Accepted
    203 false true  false false false
        Non-Authoritative Information
        Non-Authoritative Information
    204 false true  false false false
        No Content
        No Content
    205 false true  false false false
        Reset Content
        Reset Content
    206 false true  false false false
        Partial Content
        Partial Content |}]

let%expect_test _ =
  redirection |> List.map Dream.status_to_int |> List.iter show_status_code;
  [%expect {|
    300 false false true  false false
        Multiple Choices
        Multiple Choices
    301 false false true  false false
        Moved Permanently
        Moved Permanently
    302 false false true  false false
        Found
        Found
    303 false false true  false false
        See Other
        See Other
    304 false false true  false false
        Not Modified
        Not Modified
    307 false false true  false false
        Temporary Redirect
        Temporary Redirect
    308 false false true  false false
        Permanent Redirect
        Permanent Redirect |}]

let%expect_test _ =
  client_error |> List.map Dream.status_to_int |> List.iter show_status_code;
  [%expect {|
    400 false false false true  false
        Bad Request
        Bad Request
    401 false false false true  false
        Unauthorized
        Unauthorized
    402 false false false true  false
        Payment Required
        Payment Required
    403 false false false true  false
        Forbidden
        Forbidden
    404 false false false true  false
        Not Found
        Not Found
    405 false false false true  false
        Method Not Allowed
        Method Not Allowed
    406 false false false true  false
        Not Acceptable
        Not Acceptable
    407 false false false true  false
        Proxy Authentication Required
        Proxy Authentication Required
    408 false false false true  false
        Request Timeout
        Request Timeout
    409 false false false true  false
        Conflict
        Conflict
    410 false false false true  false
        Gone
        Gone
    411 false false false true  false
        Length Required
        Length Required
    412 false false false true  false
        Precondition Failed
        Precondition Failed
    413 false false false true  false
        Payload Too Large
        Payload Too Large
    414 false false false true  false
        URI Too Long
        URI Too Long
    415 false false false true  false
        Unsupported Media Type
        Unsupported Media Type
    416 false false false true  false
        Range Not Satisfiable
        Range Not Satisfiable
    417 false false false true  false
        Expectation Failed
        Expectation Failed
    421 false false false true  false
        Misdirected Request
        Misdirected Request
    425 false false false true  false
        Too Early
        Too Early
    426 false false false true  false
        Upgrade Required
        Upgrade Required
    428 false false false true  false
        Precondition Required
        Precondition Required
    429 false false false true  false
        Too Many Requests
        Too Many Requests
    431 false false false true  false
        Request Header Fields Too Large
        Request Header Fields Too Large
    451 false false false true  false
        Unavailable For Legal Reasons
        Unavailable For Legal Reasons |}]

let%expect_test _ =
  server_error |> List.map Dream.status_to_int |> List.iter show_status_code;
  [%expect {|
    500 false false false false true
        Internal Server Error
        Internal Server Error
    501 false false false false true
        Not Implemented
        Not Implemented
    502 false false false false true
        Bad Gateway
        Bad Gateway
    503 false false false false true
        Service Unavailable
        Service Unavailable
    504 false false false false true
        Gateway Timeout
        Gateway Timeout
    505 false false false false true
        HTTP Version Not Supported
        HTTP Version Not Supported |}]

(* Some numeric codes that don't correspond to any variands. *)

let%expect_test _ =
  show_status_code  98;
  show_status_code 198;
  show_status_code 298;
  show_status_code 398;
  show_status_code 498;
  show_status_code 598;
  show_status_code 698;
  [%expect {|
     98 false false false false false
        None
        98
    198 true  false false false false
        None
        198
    298 false true  false false false
        None
        298
    398 false false true  false false
        None
        398
    498 false false false true  false
        None
        498
    598 false false false false true
        None
        598
    698 false false false false false
        None
        698 |}]

(* Some non-standard or non-HTTP status codes that have reason strings assigned
   by Dream. *)
let%expect_test _ =
  show_status_code 102;
  show_status_code 103;
  show_status_code 207;
  show_status_code 208;
  show_status_code 228;
  show_status_code 305;
  show_status_code 306;
  show_status_code 418;
  show_status_code 422;
  show_status_code 423;
  show_status_code 424;
  show_status_code 506;
  show_status_code 507;
  show_status_code 508;
  show_status_code 510;
  show_status_code 511;
  [%expect {|
    102 true  false false false false
        Processing
        Processing
    103 true  false false false false
        Early Hints
        Early Hints
    207 false true  false false false
        Multi-Status
        Multi-Status
    208 false true  false false false
        Already Reported
        Already Reported
    228 false true  false false false
        IM Used
        IM Used
    305 false false true  false false
        Use Proxy
        Use Proxy
    306 false false true  false false
        Switch Proxy
        Switch Proxy
    418 false false false true  false
        I'm a teapot
        I'm a teapot
    422 false false false true  false
        Unprocessable Entity
        Unprocessable Entity
    423 false false false true  false
        Locked
        Locked
    424 false false false true  false
        Failed Dependency
        Failed Dependency
    506 false false false false true
        Variant Also Negotiates
        Variant Also Negotiates
    507 false false false false true
        Insufficient Storage
        Insufficient Storage
    508 false false false false true
        Loop Detected
        Loop Detected
    510 false false false false true
        Not Extended
        Not Extended
    511 false false false false true
        Network Authentication Required
        Network Authentication Required |}]

let equal status_1 status_2 =
  Printf.printf "%B\n" (Dream.status_codes_equal status_1 status_2)

let%expect_test _ =
  equal `OK `OK;
  equal `OK `Not_Found;
  equal `Not_Found `OK;
  equal `Not_Found `Not_Found;
  equal `OK (`Status 200);
  equal (`Status 200) `OK;
  equal `OK (`Status 404);
  [%expect {|
    true
    false
    false
    true
    true
    true
    false |}]
