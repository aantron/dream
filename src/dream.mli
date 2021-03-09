type _ message

type incoming
type outgoing

type request = incoming message
type response = outgoing message

type handler = request -> response Lwt.t
type middleware = handler -> handler

type app



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
  | `Code of int
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



val request :
  ?client:string ->
  ?method_:method_ ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  string ->
    request

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
val version : request -> int * int

val with_client : string -> request -> request
val with_method_ : method_ -> request -> request
val with_target : string -> request -> request
val with_version : int * int -> request -> request
(* TODO Generalize version to work with responses. *)

(* TODO Expose path. *)

val header : string -> _ message -> string option
val headers : string -> _ message -> string list
val has_header : string -> _ message -> bool
val all_headers : _ message -> (string * string) list

val add_header : string -> string -> 'a message -> 'a message
val drop_header : string -> 'a message -> 'a message
val with_header : string -> string -> 'a message -> 'a message

(* TODO Consider adding Dream.or_exn, Dream.bad_response_exns, and some
   state. Show how to apply a middleware right at a handler. *)

val cookies : request -> (string * string) list
val cookie : string -> request -> string
val cookie_option : string -> request -> string option
(* TODO All the optionals for Set-Cookie. *)
(* TODO set_cookie vs. with_cookie... OTOH this is a nice way to distinguish
   the header fields. *)
(* TODO Or just provide one helper for formatting Set-Cookie and let the user
   use the header calls to actually add the header...? How often do we need to
   set a cookie? *)
val add_set_cookie : string -> string -> response -> response

val status : response -> status

val body : request -> string Lwt.t
val has_body : _ message -> bool
val with_body : ?set_content_length:bool -> string -> response -> response

val reason_override : response -> string option
val version_override : response -> (int * int) option
val reason : response -> string

val identity : middleware
val start : middleware
val request_id : ?prefix:string -> middleware
val logger : middleware
val catch :
  ?on_error:(debug:bool -> request -> response -> response Lwt.t) ->
  ?on_exn:(debug:bool -> request -> exn -> response Lwt.t) ->
  ?debug:bool ->
    middleware
(* TODO Some of these helpers actually return handlers. *)
(* TODO Actually add the ?template argument. *)
val content_length : ?buffer_streams:bool -> middleware
val synchronous : (request -> response) -> handler

type route

(* TODO Get rid of on_match *)
val router : route list -> middleware
val get : string -> handler -> route
val post : string -> handler -> route
val apply : middleware list -> route list -> route
(* TODO LATER Define helpers for other methods. *)
(* val middleware : middleware list -> route list -> route *)
(* TODO It's also possible to do *)
(*
val middleware : middleware list -> route -> route
val routes : route list -> route

but does that just increase verbosity?

Dream.router @@ Dream.routes [
  Dream.middleware [...] @@ Dream.routes [
    ...
  ];
  Dream.middleware [..] @@ Dream.routes [
    sfg
  ]
]

as compared with

Dream.router [
  Dream.apply [ ] [
  ]
  Dream.apply [ ] [
  ]
]
*)
(* TODO FINALLY the prefix middleware and prefixer in the router. *)
val crumb : string -> request -> string
(* TOdO string crumbs. *)

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

(* TODO This signature really needs to be reworked, but it's good enough for a
   proof of concept, and changes should be easy later. *)
val websocket : (string -> string Lwt.t) -> response Lwt.t

type 'a local

val new_local : ?debug:('a -> string * string) -> unit -> 'a local
(* TODO But this is annoying for locals and globals - those are generally always
   present by the time they are required.....................................
   It would absolutely suck to have to handle None for things that will not
   fail in a correctly-composed application, i.e. the presence of locals and
   globals is under the user's control, rather than due to the request. So it's
   probably better to leave local and global as returning bare values by
   default... OTOH, who ever directly reads locals and globals? It is only done
   in middleware. Maybe it is better to require middleware authors to handle
   missing locals/globals for robustness' sake. *)
val local : 'a local -> _ message -> 'a
val local_option : 'a local -> _ message -> 'a option
val with_local : 'a local -> 'a -> 'b message -> 'b message

module Request_id :
sig
  val get_option : ?request:request -> unit -> string option
end

val log : ('a, Format.formatter, unit, unit) format4 -> 'a

type ('a, 'b) log =
  ((?request:request ->
  ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b) ->
    unit

val error : ('a, unit) log
val warning : ('a, unit) log
val info : ('a, unit) log
val debug : ('a, unit) log

module Log :
sig
  type source = {
    error : 'a. ('a, unit) log;
    warning : 'a. ('a, unit) log;
    info : 'a. ('a, unit) log;
    debug : 'a. ('a, unit) log;
  }

  val source : string -> source

  type level = [
    | `Error
    | `Warning
    | `Info
    | `Debug
  ]

  val initialize :
    ?backtraces:bool ->
    ?async_exception_hook:bool ->
    ?level:level ->
    ?enable:bool ->
    unit ->
      unit

  val iter_backtrace : (string -> unit) -> string -> unit
end

(* TODO Rename to new_app. *)
val app : unit -> app

type 'a global

val new_global : ?debug:('a -> string * string) -> (unit -> 'a) -> 'a global
val global : 'a global -> request -> 'a

type error = [
  | `Bad_request of string
  | `Internal_server_error of string
  | `Exn of exn
]

type error_handler = Unix.sockaddr -> error -> response Lwt.t

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?app:app ->
  ?error_handler:error_handler ->
  handler ->
    unit Lwt.t

val run :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?app:app ->
  ?error_handler:error_handler ->
  ?greeting:bool ->
  ?stop_on_input:bool ->
  ?graceful_stop:bool ->
  handler ->
    unit

val random : int -> string

val base64url : string -> string

val first : 'a message -> 'a message
val last : 'a message -> 'a message

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

(* TODO Add exception Dream.Response/Dream.Respond. *)

(* TODO DOC attempt some graphic that shows what getters retrieve what from the
   response. *)
