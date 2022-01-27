type client
type server

type 'a message

type request = client message
type response = server message

type handler = request -> response Lwt.t
type middleware = handler -> handler

module Make
  (Pclock : Mirage_clock.PCLOCK)
  (Time : Mirage_time.S)
  (Stack : Tcpip.Stack.V4V6) : sig

  type route

  type method_ =
    [ `GET
    | `POST
    | `PUT
    | `DELETE
    | `HEAD
    | `CONNECT
    | `OPTIONS
    | `TRACE
    | `PATCH
    | `Method of string ]

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

  val random : int -> string

  val log : ('a, Format.formatter, unit, unit) format4 -> 'a

  type ('a, 'b) conditional_log =
    ((?request:request ->
     ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b) ->
      unit

  type log_level = [ `Error | `Warning | `Info | `Debug ]

  val error     : ('a, unit) conditional_log
  val warning   : ('a, unit) conditional_log
  val info      : ('a, unit) conditional_log
  (* val debug     : ('a, unit) conditional_log *)

  val param : request -> string ->  string

  type 'a promise = 'a Lwt.t

  (** {1 Responses} *)

  val response :
    ?status:[< status ] ->
    ?code:int ->
    ?headers:(string * string) list ->
      string -> response
  (** Creates a new {!type-response} with the given string as body. [~code] and
      [~status] are two ways to specify the {!type-status} code, which is [200 OK]
      by default. The headers are empty by default.

      Note that browsers may interpret lack of a [Content-Type:] header as if its
      value were [application/octet-stream] or [text/html; charset=us-ascii],
      which will prevent correct interpretation of UTF-8 strings. Either add a
      [Content-Type:] header using [~headers] or {!Dream.add_header}, or use a
      wrapper like {!Dream.html}. The modern [Content-Type:] for HTML is
      [text/html; charset=utf-8]. See {!Dream.text_html}. *)

  val respond :
    ?status:[< status ] ->
    ?code:int ->
    ?headers:(string * string) list ->
      string -> response promise
  (** Same as {!Dream.val-response}, but the new {!type-response} is wrapped in a
      {!type-promise}. *)

  val html :
    ?status:[< status ] ->
    ?code:int ->
    ?headers:(string * string) list ->
      string -> response promise
  (** Same as {!Dream.respond}, but adds [Content-Type: text/html; charset=utf-8].
      See {!Dream.text_html}.

      As your Web app develops, consider adding [Content-Security-Policy] headers,
      as described in example
      {{:https://github.com/aantron/dream/tree/master/example/w-content-security-policy#files}
      [w-content-security-policy]}. These headers are completely optional, but
      they can provide an extra layer of defense for a mature app. *)

  val json :
    ?status:[< status ] ->
    ?code:int ->
    ?headers:(string * string) list ->
      string -> response promise
  (** Same as {!Dream.respond}, but adds [Content-Type: application/json]. See
      {!Dream.application_json}. *)

  val redirect :
    ?status:[< redirection ] ->
    ?code:int ->
    ?headers:(string * string) list ->
      request -> string -> response promise
  (** Creates a new {!type-response}. Adds a [Location:] header with the given
      string. The default status code is [303 See Other], for a temporary
      redirection. Use [~status:`Moved_Permanently] or [~code:301] for a permanent
      redirection.

      If you use [~code], be sure the number follows the pattern [3xx], or most
      browsers and other clients won't actually perform a redirect.

      The {!type-request} is used for retrieving the site prefix, if the string is
      an absolute path. Most applications don't have a site prefix. *)

  val empty :
    ?headers:(string * string) list ->
      status -> response promise
  (** Same as {!Dream.val-response} with the empty string for a body. *)

  val stream :
    ?status:[< status ] ->
    ?code:int ->
    ?headers:(string * string) list ->
      (response -> unit promise) -> response promise
  (** Same as {!Dream.val-respond}, but calls {!Dream.set_stream} internally to
      prepare the response for stream writing, and then runs the callback
      asynchronously to do it. See example
      {{:https://github.com/aantron/dream/tree/master/example/j-stream#files}
      [j-stream]}.

      {[
        fun request ->
          Dream.stream (fun response ->
            let%lwt () = Dream.write response "foo" in
            Dream.close_stream response)
      ]} *)

  val websocket :
    ?headers:(string * string) list ->
      (response -> unit promise) -> response promise
  (** Creates a fresh [101 Switching Protocols] response. Once this response is
      returned to Dream's HTTP layer, the callback is passed a new
      {!type-websocket}, and the application can begin using it. See example
      {{:https://github.com/aantron/dream/tree/master/example/k-websocket#files}
      [k-websocket]} \[{{:http://dream.as/k-websocket} playground}\].

      {[
        let my_handler = fun request ->
          Dream.websocket (fun websocket ->
            let%lwt () = Dream.send websocket "Hello, world!" in
            Dream.close_websocket websocket);
      ]} *)

  val status : response -> status
  (** Response {!type-status}. For example, [`OK]. *)

(** Same as {!Dream.val-response} with the empty string for a body. *)

val static :
  loader:(string -> string -> handler) ->
    string -> handler
(** Serves static files from a local directory. See example
    {{:https://github.com/aantron/dream/tree/master/example/f-static#files}
    [f-static]}.

    {[
      let () =
        Dream.run
        @@ Dream.router {
          Dream.get "/static/**" @@ Dream.static "www/static";
        }
        @@ Dream.not_found
    ]}
*)
val respond :
  ?status:[< status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
    string -> response Lwt.t
(** Same as {!Dream.val-response}, but the new {!type-response} is wrapped in a
    {!type-promise}. *)
  type csrf_result =
    [ `Ok
    | `Expired of float
    | `Wrong_session
    | `Invalid ]

  val csrf_token : ?valid_for:float -> request -> string
  val verify_csrf_token : request -> string -> csrf_result Lwt.t

  type 'a form_result =
    [ `Ok            of 'a
    | `Expired       of 'a * float
    | `Wrong_session of 'a
    | `Invalid_token of 'a
    | `Missing_token of 'a
    | `Many_tokens   of 'a
    | `Wrong_content_type ]

  type multipart_form =
    (string * ((string option * string) list)) list

  val form : ?csrf:bool -> request -> (string * string) list form_result Lwt.t
  val multipart : ?csrf:bool -> request -> multipart_form form_result Lwt.t

  val csrf_tag : request -> string

  val form_tag :
    ?method_:method_ ->
    ?target:string ->
    ?enctype:[ `Multipart_form_data ] ->
    ?csrf_token:bool ->
      action:string -> request -> string

  val lowercase_headers : middleware
  val content_length : middleware

  val logger : middleware
  val router : route list -> middleware

  val get : string -> handler -> route
  val not_found : handler

  type error =
    { condition :
        [ `Response of response
        | `String of string
        | `Exn of exn ]
    ; layer :
        [ `App
        | `HTTP
        | `HTTP2
        | `TLS
        | `WebSocket ]
    ; caused_by :
        [ `Server
        | `Client ]
    ; request : request option
    ; response : response option
    ; client : string option
    ; severity : log_level
    ; will_send_response : bool }

  type error_handler = error -> response option Lwt.t

  val error_template :
  (error -> string -> response -> response Lwt.t) -> error_handler

  val https :
       ?stop:Lwt_switch.t
    -> port:int
    -> ?prefix:string
    -> Stack.TCP.t
    -> ?cfg:Tls.Config.server
    -> ?error_handler:error_handler
    -> handler
    -> unit Lwt.t

  val http :
       ?stop:Lwt_switch.t
    -> port:int
    -> ?prefix:string
    -> ?protocol:[ `H2 | `HTTP_1_1 ]
    -> Stack.TCP.t
    -> ?error_handler:error_handler
    -> handler
    -> unit Lwt.t
end
