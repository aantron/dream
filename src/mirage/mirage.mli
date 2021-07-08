type request
type response

type handler = request -> response Lwt.t

module Error : sig
  type error
  type error_handler = error -> response option Lwt.t
end

module Make
  (Pclock : Mirage_clock.PCLOCK)
  (Time : Mirage_time.S)
  (Stack : Mirage_stack.V4V6) : sig
  type middleware = handler -> handler
  
  type route

  type informational =
    [ `Continue
    | `Switching_Protocols ]
  
  type successful =
    [ `OK
    | `Created
    | `Accepted
    | `Non_Authoritative_Information
    | `No_Content
    | `Reset_Content
    | `Partial_Content ]
  
  type redirection =
    [ `Multiple_Choices
    | `Moved_Permanently
    | `Found
    | `See_Other
    | `Not_Modified
    | `Temporary_Redirect
    | `Permanent_Redirect ]
  
  type client_error =
    [ `Bad_Request
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
    | `Unavailable_For_Legal_Reasons ]
  
  type server_error =
    [ `Internal_Server_Error
    | `Not_Implemented
    | `Bad_Gateway
    | `Service_Unavailable
    | `Gateway_Timeout
    | `HTTP_Version_Not_Supported ]
  
  type standard_status =
    [ informational
    | successful
    | redirection
    | client_error
    | server_error ]

  type status =
    [ standard_status
    | `Status of int ]

  val html : ?status:status -> ?code:int -> ?headers:(string * string) list -> string -> response Lwt.t

  val param : string -> request -> string

  val logger : middleware
  val router : route list -> middleware

  val get : string -> handler -> route
  val not_found : handler

  val run :
       ?stop:Lwt_switch.t
    -> port:int
    -> ?prefix:string
    -> Stack.t
    -> Tls.Config.server
    -> ?error_handler:Error.error_handler
    -> handler
    -> unit Lwt.t
end
