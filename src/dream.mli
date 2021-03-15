(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(** {1 Overview}

    Dream is built on just five types:

    {[
      type request
      type response

      type handler = request -> response promise
      type middleware = handler -> handler
      type route
    ]}

    [request] and [response] are the data types of Dream. Requests contain all
    the interesting fields your application will want to read, and the
    application will handle requests by creating and returning responses.

    The other three types are for building up such request-handling functions.

    [handler]s are asynchronous functions from requests to responses. They are
    just bare functions &mdash; you can define a handler immediately:

    {[
      let greet _ =
        Dream.respond "Hello, world!"
    ]}

    Whenever you have a handler, you can pass it to {!Dream.run} to turn it into
    a working HTTP server:

    {[
      let () =
        Dream.run (fun _ ->
          Dream.respond "Hello, world!")
    ]}

    This server responds to all requests with status [200 OK] and body
    [Hello, world!].

    [middleware]s are functions that take a handler, and run some code before or
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
        @@ log_requests
        @@ greet
    ]}

    The [@@] is just the ordinary function-calling operator from OCaml's
    standard library. The above code is the same as

    {[
      let () =
        Dream.run (log_requests greet)
    ]}

    However, as we chain more and more middlewares, there will be more and more
    nested parentheses. [@@] is just a neat way to avoid that.

    `route`s are used with {!Dream.router} to select which handler each request
    should go to. They are created with helpers like {!Dream.get} and
    {!Dream.scope}:

    If you prefer a vaguely “algebraic” take on Dream:

    - Literal [handler]s are atoms.
    - [middleware] is for sequential composition (AND-like).
    - [route] is for alternative composition (OR-like). *)

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
(** [_ message], read as “any message,” allows some arguments to be either
    requests or responses:

    {[
      Dream.has_body : _ message -> bool
    ]}

    This is because both requests and responses are defined in terms of
    [_ message].

    Most functions still take specifically only requests or responses. For
    example, only requests have a target (like [/something]), so:

    {[
      Dream.target : request -> string
    ]}

    Dream only ever creates [request]s and [response]s, i.e. only
    [incoming message]s and [outgoing message]s. The type parameter is never
    used with any types other than these two. In fact, [incoming] and [outgoing]
    are never mentioned again in the docs — this section is only to help with
    interpreting arguments of type [_ message], “any message.” *)

and incoming
(** Type parameter used with [message] for requests. Has no meaning other than
    it is different from {!outgoing}. *)

and outgoing
(** Type parameter used with [message] for responses. Has no meaning other than
    it is different from {!incoming}. *)

and 'a promise = 'a Lwt.t
(** Dream uses Lwt promises and Lwt asynchronous I/O. *)



(**/**)
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

(**/**)



(** {1 Requests & responses} *)

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

val client : request -> string
val method_ : request -> method_
val target : request -> string
val prefix : request -> string
val path : request -> string
val version : request -> int * int

val with_client : string -> request -> request
val with_method_ : method_ -> request -> request
val with_version : int * int -> request -> request

val header : string -> _ message -> string option
val headers : string -> _ message -> string list
val has_header : string -> _ message -> bool
val all_headers : _ message -> (string * string) list

val add_header : string -> string -> 'a message -> 'a message
val drop_header : string -> 'a message -> 'a message
val with_header : string -> string -> 'a message -> 'a message

(* TODO LATER Consider adding Dream.or_exn, Dream.bad_response_exns, and some
   state. Show how to apply a middleware right at a handler. *)

val cookies : request -> (string * string) list
val cookie : string -> request -> string
val cookie_option : string -> request -> string option
(* TODO All the optionals for Set-Cookie. *)
(* TODO Or just provide one helper for formatting Set-Cookie and let the user
   use the header calls to actually add the header...? How often do we need to
   set a cookie? *)
val add_set_cookie : string -> string -> response -> response

val status : response -> status

val body : _ message -> string Lwt.t
val has_body : _ message -> bool
val with_body : ?set_content_length:bool -> string -> response -> response

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

(** {1 Streaming & WebSockets} *)

(* TODO This signature really needs to be reworked, but it's good enough for a
   proof of concept, and changes should be easy later. *)
val websocket : (string -> string Lwt.t) -> response Lwt.t

(** {1 Request variables} *)

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

(** {1 Running apps} *)

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

(** {1 Web formats} *)

val random : int -> string

val base64url : string -> string

(** {1 Testing} *)

val request :
  ?client:string ->
  ?method_:method_ ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  string ->
    request

val first : 'a message -> 'a message
val last : 'a message -> 'a message

val test : ?prefix:string -> handler -> (request -> response)

val sort_headers : (string * string) list -> (string * string) list
(* TODO DOC This sorts headers based on the header name, but not the value,
   because the order of values may be important.
   https://stackoverflow.com/questions/750330/does-the-order-of-headers-in-an-http-response-ever-matter *)

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
