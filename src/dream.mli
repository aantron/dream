(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(** {1 Overview}

    Dream is built on just five types. The first two, [request] and [response],
    are the data types of Dream. Requests contain all the interesting fields
    your application will want to read, and the application will handle requests
    by creating and returning responses:

    {[
      type request
      type response
    ]}

    These next three types are for building up request-handling functions:

    {[
      type handler = request -> response promise
      type middleware = handler -> handler
      type route
    ]}

    {ol
    {li
    Handlers are asynchronous functions from requests to responses. They are
    just bare functions — you can define a handler wherever you need it. Once
    you have a handler, you can pass it to {!Dream.run} to turn it into a
    working HTTP server:

    {[
      let () =
        Dream.run (fun _ ->
          Dream.respond "Hello, world!")
    ]}

    This is a complete Dream program that responds to all requests on
    {{:http://localhost:8080}} with status [200 OK] and body [Hello, world!].
    The rest of Dream is about defining ever more useful handlers.
    }

    {li
    Middlewares are functions that take a handler, and run some code before or
    after the handler runs. The result is a “bigger” handler. Middlewares are
    also just bare functions, so you can also create them immediately:

    {[
      let log_requests inner_handler =
        fun request ->
          Dream.log "Got a request!";
          inner_handler request
    ]}

    This middleware prints a message on every request, before passing the
    request to the rest of the app. You can use it with {!Dream.run}:

    {[
      let () =
        Dream.run
          (log_requests (fun _ ->
            Dream.respond "Hello, world!"))
    ]}
    }

    {li
    Routes are used with {!Dream.router} to select which handler each request
    should go to. They are created with helpers like {!Dream.get} and
    {!Dream.scope}:

    {[
      Dream.router [
        Dream.get "/" home_handler;

        Dream.scope "/admin" [] [
          Dream.get "/" admin_handler;
          Dream.get "/logout" admin_logout_handler;
        ];
      ]
    ]}
    }}

    If you prefer a vaguely “algebraic” take on Dream:

    - Literal handlers are atoms.
    - Middleware is for sequential composition (AND-like).
    - Routes are for alternative composition (OR-like). *)

(** {1 Main types} *)

type request = incoming message
(** HTTP requests, such as [GET /something HTTP/1.1]. *)

and response = outgoing message
(** HTTP responses, such as [200 OK]. *)

and handler = request -> response promise
(** Handlers are asynchronous functions from requests to responses. *)

and middleware = handler -> handler
(** Middlewares are functions that take a handler, and run some code before or
    after — producing a “bigger” handler. This is the main form of {e sequential
    composition} in Dream. *)

and route
(** Routes tell {!Dream.router} which handler to select for each request. This
    is the main form of {e alternative composition} in Dream. Routes are created
    by helpers such as {!Dream.get} and {!Dream.scope}. *)



(** {1 Helper types} *)

and _ message
(** [_ message], read as “any message,” allows {{!common_fields} some functions}
    to take either requests or responses as arguments, because both are defined
    in terms of [_ message]. For example:

    {[
      Dream.has_body : _ message -> bool
    ]}

    Dream only ever creates requests and responses, i.e. only [incoming message]
    and [outgoing message]. You don't have to worry about anything else, such as
    [int message]. [incoming] and [outgoing] are never mentioned again in the
    docs — this section is only to help with interpreting arguments of type
    [_ message], “any message.” *)

and incoming
(** Type parameter for [message] for requests. Has no meaning other than it is
    different from {!outgoing}. *)

and outgoing
(** Type parameter for [message] for responses. Has no meaning other than it is
    different from {!incoming}. *)

and 'a promise = 'a Lwt.t
(** Dream uses {{:https://github.com/ocsigen/lwt} Lwt} for promises and
    asynchronous I/O. *)



(* TODO Move these to their own page, and provide an abbreviated version on the
   main API page. *)

type method_ = [
  | `GET
  | `POST
  | `PUT
  | `DELETE
  | `HEAD
  | `CONNECT
  | `OPTIONS
  | `TRACE
  | `Method of string
]
(** HTTP methods. See {{:https://tools.ietf.org/html/rfc7231#section-4.3} RFC
    7231 §4.2}. *)

val method_to_string : method_ -> string



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
  | `Status of int
]

val status_to_string : status -> string
val status_to_reason : status -> string option
val status_to_int : status -> int
val int_to_status : int -> status

val is_informational : status -> bool
val is_success : status -> bool
val is_redirect : status -> bool
val is_client_error : status -> bool
val is_server_error : status -> bool



(** {1:request_fields Request fields} *)

val client : request -> string
(** Client sending the request, for example [127.0.0.1:56001]. *)

val method_ : request -> method_
(** Request method, for example [`GET]. See
    {{:https://tools.ietf.org/html/rfc7231#section-4.3} RFC 7231 §4.2}. *)

val target : request -> string
(** Request target, for example [/something]. This is the full path as sent by
    the client or proxy. The site root prefix is included. *)

(**/**)
(* These are used for router state at the moment, and I am not sure if there is
   a public use case for them. I may remove them from the API, and have the
   test cases access their internal definitions directly. *)
val prefix : request -> string
val path : request -> string
(**/**)

val version : request -> int * int
(** Protocol version, such as [(1, 1)] for HTTP/1.1 and [(2, 0)] for HTTP/2. *)

val with_client : string -> request -> request
(** Creates a new request from the given one, with the client string
    replaced. *)

val with_method_ : method_ -> request -> request
(** Creates a new request from the given one, with the method replaced. *)

val with_version : int * int -> request -> request
(** Creates a new request from the given one, with the protocol version
    replaced. *)

val cookie : string -> request -> string option
(** Cookies are sent by the client in [Cookie:] headers as [name=value] pairs.
    This function parses those headers, looking for the given [name]. No
    decoding is applied to any found [value] — it is returned raw, as sent by
    the client. Cookies are almost always encoded so as to at least escape [=],
    [;], and newline characters, which are significant to the cookie and HTTP
    parsers. If you applied such an encoding when setting the cookie, you have
    to reverse it after calling [Dream.cookie]. See {!Dream.add_set_cookie} for
    recommendations about encodings to use and {!web_formats} for encoders and
    decoders. *)

val all_cookies : request -> (string * string) list
(** Retrieves all cookies, i.e. all [name=value] in all [Cookie:] headers. As
    with {!Dream.cookie}, no decoding is applied to the values. *)



(** {1:common_fields Common fields} *)

val header : string -> _ message -> string option
(** Retrieves the first header with the given name, if present. *)

val headers : string -> _ message -> string list
(** Retrieves all headers with the given name. *)

val has_header : string -> _ message -> bool
(** Evaluates to [true] if and only if a header with the given name is
    present. *)

val all_headers : _ message -> (string * string) list
(** Retrieves all headers. *)

val add_header : string -> string -> 'a message -> 'a message
(** Creates a new message (request or response) by adding a header with the
    given name and value. Note that, for several header name, HTTP permits
    mutliple headers with the same name. This function therefore does not remove
    any existing headers with the same name. *)

val drop_header : string -> 'a message -> 'a message
(** Creates a new message by removing all headers with the given name. *)

val with_header : string -> string -> 'a message -> 'a message
(** Equivalent to first calling {!Dream.drop_header} and then
    {!Dream.add_header}. Creates a new message by replacing all headers with the
    given name by one header with that name and the given value. *)

val body : _ message -> string Lwt.t
(** Retrieves the body of the given message (request or response), streaming it
    to completion first, if necessary. *)

val has_body : _ message -> bool
(** Evalutes to [true] if the given message either has a body that has been
    streamed and has positive length, or a body that has not been streamed yet.
    This function does not stream the body — it could return [true], and later
    streaming could reveal that the body has length zero. *)

(* TODO Decide what to do about Content-Lengths, and then document it. *)
val with_body : ?set_content_length:bool -> string -> 'a message -> 'a message
(** Creates a new message by replacing the body with the given string. *)

(** {1 Responses} *)

val response :
  ?version:int * int ->
  ?status:status ->
  ?reason:string ->
  ?headers:(string * string) list ->
  ?set_content_length:bool ->
  string ->
    response

val respond :
  ?version:int * int ->
  ?status:status ->
  ?reason:string ->
  ?headers:(string * string) list ->
  ?set_content_length:bool ->
  string ->
    response Lwt.t

(* TODO LATER Consider adding Dream.or_exn, Dream.bad_response_exns, and some
   state. Show how to apply a middleware right at a handler. *)


(* TODO All the optionals for Set-Cookie. *)
(* TODO Or just provide one helper for formatting Set-Cookie and let the user
   use the header calls to actually add the header...? How often do we need to
   set a cookie? *)
val add_set_cookie : string -> string -> response -> response
(* TODO Hints about encodings. *)

val status : response -> status

val reason_override : response -> string option
val version_override : response -> (int * int) option
val reason : response -> string

(** {1 Middleware} *)

val identity : middleware
val start : middleware
val pipeline : middleware list -> middleware
val request_id : ?prefix:string -> middleware
val logger : middleware
val content_length : ?buffer_streams:bool -> middleware
val synchronous : (request -> response) -> handler

(** {1 Routing} *)

val get : string -> handler -> route
val post : string -> handler -> route
(* TODO LATER Define helpers for other methods. *)

val scope : string -> middleware list -> route list -> route

val router : route list -> middleware
val crumb : string -> request -> string

(* TODO For a form, you almost always match against a fixed set of fields. But
   for query parameters, there might be mixtures. *)

type session

(* TODO LATER Seriously review these signatures and names. *)
val sessions : middleware
val session : request -> session
(* TODO LATER Expose the session switcher and invalidator. *)

val csrf : middleware
val form : middleware
(* TODO Naming, naming. *)
val form_get : request -> (string * string) list
(* TODO There is no strong reason why Form should be a middleware; it can just
   be a caching getter like Cookie. CSRF will load it on demand depending on
   content-type. Will probably need a Content-Type filter middleware, however,
   because that needs to go before CSRF. Maybe there should be a function form
   of CSRF? Is there really any reason at all why CSRF should be a middleware
   itself? Can just provide some middleware that allows running checks, and
   provide the checks. I guess the main reason why any of these things are
   middlewares is that CSRF can respond on its own. *)

(** {1 Streaming} *)

(** {1 WebSockets} *)

(* TODO This signature really needs to be reworked, but it's good enough for a
   proof of concept, and changes should be easy later. *)
val websocket : (string -> string Lwt.t) -> response Lwt.t

(** {1 Message variables} *)

type 'a local

val new_local : ?debug:('a -> string * string) -> unit -> 'a local
val local : 'a local -> _ message -> 'a option
val with_local : 'a local -> 'a -> 'b message -> 'b message

module Request_id :
sig
  val get_option : ?request:request -> unit -> string option
end

(** {1 Logging} *)

val log : ('a, Format.formatter, unit, unit) format4 -> 'a

type ('a, 'b) log_writer =
  ((?request:request ->
  ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b) ->
    unit

val error : ('a, unit) log_writer
val warning : ('a, unit) log_writer
val info : ('a, unit) log_writer
val debug : ('a, unit) log_writer

module Log :
sig
  type level = [
    | `Error
    | `Warning
    | `Info
    | `Debug
  ]

  (* TODO Well, the type name conflicts... *)
  type log = {
    error : 'a. ('a, unit) log_writer;
    warning : 'a. ('a, unit) log_writer;
    info : 'a. ('a, unit) log_writer;
    debug : 'a. ('a, unit) log_writer;
  }

  val initialize :
    ?backtraces:bool ->
    ?async_exception_hook:bool ->
    ?level:level ->
    ?enable:bool ->
    unit ->
      unit

  (* val iter_backtrace : (string -> unit) -> string -> unit *)
end

val new_log : string -> Log.log

type app

val new_app : unit -> app

type 'a global

val new_global : ?debug:('a -> string * string) -> (unit -> 'a) -> 'a global
val global : 'a global -> request -> 'a

(** {1 Error page} *)

type error = {
  condition : [
    | `Response
    | `String of string
    | `Exn of exn
  ];
  layer : [
    | `TLS
    | `HTTP
    | `HTTP2
    | `WebSocket
    | `App
  ];
  caused_by : [
    | `Server
    | `Client
  ];
  request : request option;
  response : response option;
  client : string option;
  severity : Log.level;
  debug : bool;
  will_send_response : bool;
}

type error_handler = error -> response option Lwt.t

val error_handler_with_template :
  (debug_info:string option -> response -> response Lwt.t) -> error_handler

(** {1 HTTP} *)

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?debug:bool ->
  ?error_handler:error_handler ->
  ?prefix:string ->
  ?app:app ->
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
  handler ->
    unit Lwt.t

val run :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?debug:bool ->
  ?error_handler:error_handler ->
  ?prefix:string ->
  ?app:app ->
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
  ?greeting:bool ->
  ?stop_on_input:bool ->
  ?graceful_stop:bool ->
  handler ->
    unit

(** {1:web_formats Web formats} *)

val base64url : string -> string

(** {1 Entropy} *)

val random : int -> string

(** {1 Testing & debugging} *)

val request :
  ?client:string ->
  ?method_:method_ ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  string ->
    request
(** [Dream.request body] creates a fresh request with the given body for
    testing. The optional arguments set the corresponding {{!request_fields}
    request fields}. *)

val first : 'a message -> 'a message
(** [Dream.first message] evaluates to the original request or response that
    [message] is immutably derived from. This is useful for getting the original
    state of requests especially, when they were first created inside the HTTP
    server ({!Dream.run}). *)

val last : 'a message -> 'a message
(** [Dream.last message] evaluates to the latest request or response that was
    derived from [message]. This is most useful for obtaining the state of
    requests at the time an exception was raised, without having to instrument
    the latest version of the request before the exception. *)

val test : ?prefix:string -> handler -> (request -> response)
(** [Dream.test handler] runs a handler the same way the HTTP server
    ({!Dream.run}) would — assigning it a request id and noting the site root
    prefix, which is used by routers. [Dream.test] calls [Lwt_main.run]
    internally to await the response, which is why the response returned from
    the test is not wrapped in a promise. If you don't need these facilities,
    you can test [handler] by calling it directly with a request. *)

val sort_headers : (string * string) list -> (string * string) list
(** Sorts headers by name. Headers with the same name are not sorted by value or
    otherwise reordered, because order is significant for some headers. See
    {{:https://tools.ietf.org/html/rfc7230#section-3.2.2} RFC 7230 §3.2.2} on
    header order. This function can help sanitize output before comparison. *)

(* TODO DOC that [stop] only stops the server listening - requests already
   in the server can continue executing. *)
(* TODO DOC Can probably also get `Exn upon failure to stream the body. *)
(* TODO DOC `Bad_gateway and `Internal_server_error occur when the application
   returns a negative content-length, or no content-length when one is
   required. *)
(* TODO DOC Can't even define the response type fully.. or can we? Can just
   reuse the Dream response, but note that the status will be ignored. *)
(* TODO DOC Figure out the behavior of various strings one could pass for the
   interface and DOCUMENT. *)
(* TODO DOC What happens if the error handler also raises an exception? *)
(* TODO DOC Placate the user: the error handler is generally not necessary. *)
(* TODO DOC Give people a tip: a basic response needs either content-length or
   connection: close. *)

(* TODO LATER Add exception Dream.Response/Dream.Respond. *)

(* TODO DOC attempt some graphic that shows what getters retrieve what from the
   response. *)

(* TODO Add clone. *)
