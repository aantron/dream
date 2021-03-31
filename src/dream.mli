(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(** {1 Types}

    Dream is built on just five types. The first two are the data types of
    Dream: *)

type request = incoming message
(** HTTP requests, such as [GET /something HTTP/1.1]. See
    {!section-requests}. *)

and response = outgoing message
(** HTTP responses, such as [200 OK]. See {!section-responses}. *)

(** The remaining three types are for building up web apps. *)

and handler = request -> response promise
(** Handlers are asynchronous functions from requests to responses. Example
    {{:https://github.com/aantron/dream/tree/master/example/1-hello#files}
    [1-hello]} shows the simplest handler, an anonymous function which we pass
    to {!Dream.run}. This creates a complete web server!

    {[
      let () =
        Dream.run (fun _ ->
          Dream.respond "Good morning, world!")
    ]} *)

and middleware = handler -> handler
(** Middlewares are functions that take a {!handler}, and run some code before
    or after — producing a “bigger” handler. Example
    {{:https://github.com/aantron/dream/tree/master/example/2-middleware#files}
    [2-middleware]} inserts the {!Dream.logger} middleware into a web app:

    {[
      let () =
        Dream.run
        @@ Dream.logger
        @@ fun _ ->
          Dream.respond "Good morning, world!"
    ]}

    Examples
    {{:https://github.com/aantron/dream/tree/master/example/4-counter#files}
    [4-counter]} and
    {{:https://github.com/aantron/dream/tree/master/example/a-promise#files}
    [a-promise]} show user-defined middlewares:

    {[
      let count_requests inner_handler request =
        count := !count + 1;
        inner_handler request
    ]} *)

and route
(** Routes tell {!Dream.router} which handler to select for each request. See
    {!section-routing} and example
    {{:https://github.com/aantron/dream/tree/master/example/3-router#files}
    [3-router]}. Routes are created by helpers such as {!Dream.get} and
    {!Dream.scope}:

    {[
      Dream.router [
        Dream.scope "/admin" [Dream.sessions_in_memory] [
          Dream.get "/" admin_handler;
          Dream.get "/logout" admin_logout_handler;
        ];
      ]
    ]}

    The three handler-related types have a vaguely algebraic interpretation:

    - Literal {!type-handler}s are atoms.
    - {!type-middleware} is for sequential composition (product-like).
    - {!type-route} is for alternative composition (sum-like).

    {!Dream.scope} implements a distributive law. *)

(** {2 Helpers} *)

and 'a message
(** ['a message], pronounced “any message,” allows some functions to take either
    {!type-request} or {!type-response} as arguments, because both are defined
    in terms of ['a message]. For example, in {!section-headers}:

    {[
      val Dream.header : string -> 'a message -> string option
    ]} *)

and incoming
and outgoing
(** Type parameters for {!message} for {!type-request} and {!type-response},
    respectively. These have no meaning other than they are different from each
    other. Dream only ever creates [incoming message] and [outgoing message].
    [incoming] and [outgoing] are never mentioned again in the docs. *)

and 'a promise = 'a Lwt.t
(** Dream uses {{:https://github.com/ocsigen/lwt} Lwt} for promises and
    asynchronous I/O. See example
    {{:https://github.com/aantron/dream/tree/master/example/a-promise#files}
    [a-promise]}. *)



(* TODO Framework never emits `Method, `Status when not necessary. *)
(* TODO Normalize metods and statuses whenever they are set. Maybe provide a
   normalize helper? *)
(** The only purpose of this submodule is to generate a subpage, so as to move
    helpers and repetitive defintions of seldom-used codes out of the main
    docs. The module is immediately included in the main API. *)
module Method_and_status :
sig

(** {0 Methods and status codes} *)

(** {1 Methods} *)

type method_ = [
  | `GET
  | `POST
  | `PUT
  | `DELETE
  | `HEAD
  | `CONNECT
  | `OPTIONS
  | `TRACE
  | `PATCH
  | `Method of string
]
(** HTTP request methods. See
    {{:https://tools.ietf.org/html/rfc7231#section-4.3} RFC 7231 §4.2},
    {{:https://tools.ietf.org/html/rfc5789#page-2} RFC 5789 §2}, and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods} MDN}. *)

val method_to_string : method_ -> string
(** Evaluates to a string representation of the given method. For example,
    [`GET] is converted to ["GET"]. *)

val string_to_method : string -> method_
(** Evaluates to the {!type-method_} corresponding to the given method
    string. *)

val methods_equal : method_ -> method_ -> bool
(** Compares two methods, such that equal methods are detected even if one is
    represented as a string. For example,

    {[
      Dream.methods_equal `GET (`Method "GET") = true
    ]} *)

(** {1:status_codes Status codes} *)

type informational = [
  | `Continue
  | `Switching_Protocols
]
(** Informational ([1xx]) status codes. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.2} RFC 7231 §6.2} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#information_responses}
    MDN}. [101 Switching Protocols] is generated internally by
    {!Dream.val-websocket}. It is usually not necessary to use it directly. *)

type successful = [
  | `OK
  | `Created
  | `Accepted
  | `Non_Authoritative_Information
  | `No_Content
  | `Reset_Content
  | `Partial_Content
]
(** Successful ([2xx]) status codes. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.3} RFC 7231 §6.3},
    {{:https://tools.ietf.org/html/rfc7233#section-4.1} RFC 7233 §4.1} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#successful_responses}
    MDN}. The most common is [200 OK]. *)

type redirection = [
  | `Multiple_Choices
  | `Moved_Permanently
  | `Found
  | `See_Other
  | `Not_Modified
  | `Temporary_Redirect
  | `Permanent_Redirect
]
(** Redirection ([3xx]) status codes. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.4} RFC 7231 §6.4} and
    {{:https://tools.ietf.org/html/rfc7538#section-3} RFC 7538 §3}, and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#redirection_messages}
    MDN}. Use [303 See Other] to direct clients to follow up with a [GET]
    request, especially after a form submission. Use [301 Moved Permanently]
    for permanent redirections. *)

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
(** Client error ([4xx]) status codes. The most common are [400 Bad Request],
    [401 Unauthorized], [403 Forbidden], and, of course, [404 Not Found].

    See
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#client_error_responses}
    MDN}, and

    - {{:https://tools.ietf.org/html/rfc7231#section-6.5} RFC 7231 §6.5} for
      most client error status codes.
    - {{:https://tools.ietf.org/html/rfc7233#section-4.4} RFC 7233 §4.4} for
      [416 Range Not Satisfiable].
    - {{:https://tools.ietf.org/html/rfc7540#section-9.1.2} RFC 7540 §9.1.2} for
      [421 Misdirected Request].
    - {{:https://tools.ietf.org/html/rfc8470#section-5.2} RFC 8470 §5.2} for
      [425 Too Early].
    - {{:https://tools.ietf.org/html/rfc6585} RFC 6585} for
      [428 Precondition Required], [429 Too Many Requests], and [431 Request
      Headers Too Large].
    - {{:https://tools.ietf.org/html/rfc7725} RFC 7725} for
      [451 Unavailable For Legal Reasons]. *)

type server_error = [
  | `Internal_Server_Error
  | `Not_Implemented
  | `Bad_Gateway
  | `Service_Unavailable
  | `Gateway_Timeout
  | `HTTP_Version_Not_Supported
]
(** Server error ([5xx]) status codes. See
    {{:https://tools.ietf.org/html/rfc7231#section-6.6} RFC 7231 §6.6} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#server_error_responses}
    MDN}. The most common of these is [500 Internal Server Error]. *)

type standard_status = [
  | informational
  | successful
  | redirection
  | client_error
  | server_error
]
(** Sum of all the status codes declared above. *)

type status = [
  | standard_status
  | `Status of int
]
(** Status codes, including codes directly represented as integers. See the
    types above for the full list and references. *)

val status_to_string : status -> string
(** Evaluates to a string representation of the given status. For example,
    [`Not_Found] and [`Status 404] are both converted to ["Not Found"]. Numbers
    are used for unknown status codes. For example, [`Status 567] is converted
    to ["567"]. *)

val status_to_reason : status -> string option
(** Converts known status codes to their string representations. Evaluates to
    [None] for unknown status codes. *)

val status_to_int : status -> int
(** Evaluates to the numeric value of the given status code. *)

val int_to_status : int -> status
(** Evaluates to the symbolic representation of the status code with the given
    number. *)

val is_informational : status -> bool
(** Evaluates to [true] if the given status is either from type
    {!Dream.informational}, or is in the range [`Status 100] — [`Status 199]. *)

val is_successful : status -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.successful} and numeric
    codes [2xx]. *)

val is_redirection : status -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.redirection} and
    numeric codes [3xx]. *)

val is_client_error : status -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.client_error} and
    numeric codes [4xx]. *)

val is_server_error : status -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.server_error} and
    numeric codes [5xx]. *)

val status_codes_equal : status -> status -> bool
(** Compares two status codes, such that equal codes are detected even if one is
    represented as a number. For example,

    {[
      Dream.status_codes_equal `Not_Found (`Status 404) = true
    ]} *)

end

(**/**)
include module type of Method_and_status
(**/**)



(** {1 Requests} *)

type method_ = Method_and_status.method_
(** Request methods. See
    {{:https://tools.ietf.org/html/rfc7231#section-4.3} RFC 7231 §4.2} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods} MDN}. The full
    set is defined on a {{:/method_and_status/index.html#methods} separate
    page}. *)

val client : request -> string
(** Client sending the request. For example, ["127.0.0.1:56001"]. *)

val https : request -> bool
(** Whether the request was sent over HTTPS. *)
(* TODO There needs to be a way of setting this based on proxy headers, also. *)

val method_ : request -> method_
(** Request method. For example, [`GET]. *)

val target : request -> string
(** Request target path. For example, ["/something"]. *)

(**/**)
(* These are used for router state at the moment, and I am not sure if there is
   a public use case for them. I may remove them from the API, and have the
   test cases access their internal definitions directly. *)
val prefix : request -> string
val path : request -> string
(**/**)

val version : request -> int * int
(** Protocol version. [(1, 1)] for HTTP/1.1 and [(2, 0)] for HTTP/2. *)

val with_client : string -> request -> request
(** Replaces the client. See {!Dream.client}. *)

val with_method_ : method_ -> request -> request
(** Replaces the method. See {!Dream.method_}. *)

val with_version : int * int -> request -> request
(** Replaces the version. See {!Dream.version}. *)

val query : string -> request -> string option
(** First query parameter with the given name. See
    {{:https://tools.ietf.org/html/rfc3986#section-3.4} RFC 3986 §3.4} and
    example
    {{:https://github.com/aantron/dream/tree/master/example/w-query#files}
    [w-query]}. *)

val queries : string -> request -> string list
(** All query parameters with the given name. *)

val all_queries : request -> (string * string) list
(** Entire query string as a name-value list. *)



(** {1 Responses} *)

type status = Method_and_status.status
(** Response status codes. See
    {{:https://tools.ietf.org/html/rfc7231#section-6} RFC 7231 §6} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Status} MDN}. The full
    set is defined on a {{:/method_and_status/index.html#status_codes} separate
    page}. *)

val status : response -> status
(** Response {!type-status}. For example, [`OK]. *)

val response :
  ?status:status ->
  ?code:int ->
  ?headers:(string * string) list ->
    string -> response
(** Creates a new {!type-response} with the given string as body. [~code] and
    [~status] are two ways to specify the {!type-status} code, which is [200 OK]
    by default. The headers are empty by default. *)

val respond :
  ?status:status ->
  ?code:int ->
  ?headers:(string * string) list ->
    string -> response promise
(** Same as {!Dream.val-response}, but the new {!type-response} is wrapped in a
    {!type-promise}. *)

val empty :
  ?headers:(string * string) list ->
    status -> response promise
(** Same as {!Dream.val-response} with the empty string for a body. *)

val stream :
  ?status:status ->
  ?code:int ->
  ?headers:(string * string) list ->
    (response -> unit promise) -> response promise
(** Same as {!Dream.val-respond}, but calls {!Dream.with_stream} internally to
    prepare the response for stream writing, and then runs the callback
    asynchronously to do it. See example
    {{:https://github.com/aantron/dream/tree/master/example/j-stream#files}
    [j-stream]}.

    {[
      fun request ->
        Dream.stream (fun response ->
          let%lwt () = Dream.write "foo" response in
          Dream.close_stream response)
    ]} *)



(** {1 Headers} *)

val header : string -> 'a message -> string option
(** First header with the given name. Header names are case-insensitive. See
    {{:https://tools.ietf.org/html/rfc7230#section-3.2} RFC 7230 §3.2} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers} MDN}. *)

val headers : string -> 'a message -> string list
(** All headers with the given name. *)

val all_headers : 'a message -> (string * string) list
(** Entire header set as name-value list. *)

val has_header : string -> 'a message -> bool
(** Whether the message has a header with the given name. *)

val drop_header : string -> 'a message -> 'a message
(** Removes all headers with the given name. *)

val add_header : string -> string -> 'a message -> 'a message
(** Appends a header with the given name and value. Does not remove any existing
    headers with the same name. *)

val with_header : string -> string -> 'a message -> 'a message
(** Equivalent to {!Dream.drop_header} followed by {!Dream.add_header}. *)



(** {1 Cookies} *)

(* TODO How to delete cookies. *)
(* TODO Add ability to only sign the cookie? *)
val set_cookie :
  ?prefix:[ `Host | `Secure ] option ->
  ?encrypt:bool ->
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[ `Strict | `Lax | `None ] option ->
    string -> string -> request -> response -> response
(** Appends a [Set-Cookie:] header to the given {!response}. Infers the most
    secure defaults from the {!type-request}.

    {[
      Dream.set_cookie "my.cookie" "value" request response
    ]}

    Specify {!Dream.run} argument [~secret], or the web app will not be able to
    decrypt cookies from prior starts.

    See example
    {{:https://github.com/aantron/dream/tree/master/example/c-cookie#files}
    [c-cookie]}.

    Most of the optional arguments are for overriding inferred defaults.
    [~expires] and [~max_age] are independently useful.

    - [~prefix] sets [__Host-], [__Secure-], or no prefix, from most secure to
      least. A conforming client will refuse to accept the cookie if [~domain],
      [~path], and [~secure] don't match the constraints implied by the prefix.
      By default, {!Dream.set_cookie} chooses the most restrictive prefix based
      on the other settings and the {!type-request}. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.3}
      RFC 6265bis §4.1.3} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Cookie_prefixes}
      MDN}.
    - [~encrypt:false] disables cookie encryption. In that case, you must make
      sure that the cookie value does not contain [=], [;], or newlines. The
      easiest way to do so is to pass the value through an encoder like
      {!Dream.to_base64url}. See {!Dream.run} argument [~secret].
    - [~expires] sets the [Expires=] attribute. The value is compatible with
      {{:https://caml.inria.fr/pub/docs/manual-ocaml/libref/Unix.html#VALgettimeofday}
      [Unix.gettimeofday]}. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.1}
      RFC 6265bis §4.1.2.1} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#define_the_lifetime_of_a_cookie}
      MDN}.
    - [~max_age] sets the [Max-Age=] attribute. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.2}
      RFC 6265bis §4.1.2.2} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#define_the_lifetime_of_a_cookie}
      MDN}.
    - [~domain] sets the [Domain=] attribute. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.3}
      RFC 6265bis §4.1.2.3} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Domain_attribute}
      MDN}.
    - [~path] sets the [Path=] attribute. By default, [Path=] set to the site
      prefix in the {!type-request}, which is usually [/]. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.4}
      RFC 6265bis §4.1.2.4} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Path_attribute}
      MDN}.
    - [~secure] sets the [Secure] attribute. By default, [Secure] is set if
      {!Dream.https} is [true] for the {!type-request}. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.5}
      RFC 6265bis §4.1.2.5} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#restrict_access_to_cookies}
      MDN}.
    - [~http_only] sets the [HttpOnly] attribute. [HttpOnly] is set by default.
      See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.6}
      RFC 6265bis §4.1.2.6} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#restrict_access_to_cookies}
      MDN}.
    - [~same_site] sets the [SameSite=] attribute. [SameSite] is set to [Strict]
      by default. See
      {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.1.2.7}
      RFC 6265bis §4.1.2.7} and
      {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#SameSite_attribute}
      MDN}.

    {!Dream.to_set_cookie} is a “raw” version of this function that does not do
    any inference.

 *)
(* TODO Add a percent encoding and link it. *)
(* TODO HTTPS and proxies. *)

val cookie :
  ?prefix:[ `Host | `Secure ] option ->
  ?decrypt:bool ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
    string -> request -> string option
(** First cookie with the given name. See example
    {{:https://github.com/aantron/dream/tree/master/example/c-cookie#files}
    [c-cookie]}.

    {[
      Dream.cookie "my.cookie" request
    ]}

    Pass the same optional arguments as to {!Dream.set_cookie} for the same
    cookie. This will allow {!Dream.cookie} to infer the cookie name prefix,
    implementing a transparent cookie round trip with the most secure attributes
    applicable. *)

val all_cookies : request -> (string * string) list
(** All cookies, with raw names and values. *)



(** {1 Bodies} *)

val body : 'a message -> string promise
(** Retrieves the entire body. Stores a reference, so {!Dream.body} can be used
    many times. See example
    {{:https://github.com/aantron/dream/tree/master/example/5-echo#files}
    [5-echo]}. *)

val with_body : string -> response -> response
(** Replaces the body. *)

(** {2 Streaming} *)

val read : request -> string option promise
(** Retrieves a body chunk. The chunk is not buffered, thus it can only be read
    once. See example
    {{:https://github.com/aantron/dream/tree/master/example/j-stream#files}
    [j-stream]}. *)

(* TODO Can still use a multishot, pull stream? *)
val with_stream : response -> response
(** Makes the {!response} ready for stream writing with {!Dream.write}. You
    should return it from your handler soon after — only one call to
    {!Dream.write} will be accepted before then. See {!Dream.stream} for a more
    convenient wrapper. *)

val write : string -> response -> unit promise
(** Streams out the string. The promise is fulfilled when the response can
    accept more writes. *)

val flush : response -> unit promise
(** Flushes write buffers. Data is sent to the client. *)

val close_stream : response -> unit promise
(** Finishes the response stream. *)

(**/**)
val has_body : _ message -> bool
(** Evalutes to [true] if the given message either has a body that has been
    streamed and has positive length, or a body that has not been streamed yet.
    This function does not stream the body — it could return [true], and later
    streaming could reveal that the body has length zero. *)
(* TODO Should probably be generalized to return more information about what the
   stream actually is. *)
(**/**)

(** {2 Low-level streaming} *)

type bigstring =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
(** Byte arrays in the C heap. See
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bigarray.Array1.html}
    [Bigarray.Array1]}. This type is also found in several libraries installed
    by Dream, so their functions can be used with {!Dream.bigstring}:

    - {{:https://github.com/inhabitedtype/bigstringaf/blob/353cb283aef4c261597f68154eb27a138e7ef112/lib/bigstringaf.mli}
      [Bigstringaf.t]} in bigstringaf.
    - {{:https://ocsigen.org/lwt/latest/api/Lwt_bytes} [Lwt_bytes.t]} in Lwt.
    - {{:https://github.com/mirage/ocaml-cstruct/blob/9a8b9a79bdfa2a1b8455bc26689e0228cc6fac8e/lib/cstruct.mli#L139}
      [Cstruct.buffer]} in Cstruct. *)

val next :
  bigstring:(bigstring -> int -> int -> unit) ->
  (* ?string:(string -> int -> int -> unit) ->
  ?flush:(unit -> unit) -> *)
  close:(unit -> unit) ->
  exn:(exn -> unit) ->
  request ->
    unit
(** Waits for the next stream event, and calls:

    - [~bigstring] with an offset and length, if a {!bigstring} is written,
    - [~close] if close is requested, and
    - [~exn] to report an exception. *)

val write_bigstring : bigstring -> int -> int -> response -> unit promise
(** Streams out the {!bigstring} slice. *)



(* TODO Link to examples. *)
(** {1 JSON}

    Dream presently recommends using
    {{:https://github.com/ocaml-community/yojson#readme} Yojson}. See also
    {{:https://github.com/janestreet/ppx_yojson_conv#readme} ppx_yojson_conv}
    for generating JSON parsers and serializers for OCaml data types. *)

val origin_referer_check : middleware
(** CSRF protection for AJAX requests. Either the method must be [`GET] or
    [`HEAD], or:

    - [Origin:] or [Referer:] must be present, and
    - their value must match [Host:]

    Responds with [400 Bad Request] if the check fails.

    Implements the
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#verifying-origin-with-standard-headers}
    OWASP Verifying Origin With Standard Headers} CSRF defense-in-depth
    technique, which is good enough for basic usage. Do not allow [`GET] or
    [`HEAD] requests to trigger important side effects if relying only on
    {!Dream.origin_referer_check}.

    Future extensions to this function may use [X-Forwarded-Host] or host
    whitelists.

    For more thorough protection, generate CSRF tokens with {!Dream.csrf_token},
    send them to the client (for instance, in [<meta>] tags of a single-page
    application), and require their presence in an [X-CSRF-Token:] header. *)
(* TODO Basic JSON, JSON token csrf. *)



(** {1 Forms} *)

type 'a form_result = [
  | `Ok            of 'a
  | `Expired       of 'a * float
  | `Wrong_session of 'a
  | `Invalid_token of 'a
  | `Missing_token of 'a
  | `Many_tokens   of 'a
  | `Wrong_content_type
]
(** Form validation results, in order from least to most severe. See
    {!Dream.val-form} and example
    {{:https://github.com/aantron/dream/tree/master/example/d-form#files}
    [d-form]}.

    The first three constructors, [`Ok], [`Expired], and [`Wrong_session] can
    occur in regular usage.

    The remaining constructors, [`Invalid_token], [`Missing_token],
    [`Many_tokens], [`Wrong_content_type] correspond to bugs, suspicious
    activity, or tokens so old that decryption keys have since been rotated on
    the server. *)

(* TODO Link to the tag helper for dream.csrf and backup instructions for
   generating it; also create that page! *)
val form : request -> (string * string) list form_result promise
(** Parses the request body as a form. Performs checks, which are made
    transparent by using {!Dream.Tag.form} in a template. See
    {!section-templates} and example
    {{:https://github.com/aantron/dream/tree/master/example/d-form#readme}
    [d-form]},

    - [Content-Type:] must be [application/x-www-form-urlencoded].
    - The form must have a field named [dream.csrf]. {!Dream.Tag.form} adds such
      a field.
    - {!Dream.form} calls {!Dream.verify_csrf_token} to check the token in
      [dream.csrf].

    The call must be done under a session middleware, since CSRF tokens are
    bound to sessions. See {!section-sessions}.

    Form fields are sorted for easy pattern matching:

    {[
      match%lwt Dream.form request with
      | `Ok ["email", email; "name", name] -> (* ... *)
      | _ -> Dream.empty `Bad_Request
    ]}

    If you want to recover from conditions like expired forms, add extra cases:

    {[
      match%lwt Dream.form request with
      | `Ok      ["email", email; "name", name] -> (* ... *)
      | `Expired ["email", email; "name", name] -> (* ... *)
      | _ -> Dream.empty `Bad_Request
    ]}

    It is recommended not to mutate state or send back sensitive data in the
    [`Expired] and [`Wrong_session] cases, as they {e may} indicate an attack
    against a client.

    The remaining cases, including unexpected field sets and the remaining
    constructors of {!Dream.type-form_result}, usually indicate either bugs or
    attacks. It's usually fine to respond to all of them with [400 Bad
    Request]. *)
(* TODO Provide optionals for disabling CSRF checking and CSRF token field
   filtering. *)
(* TODO AJAX CSRF example with X-CSRF-Token, then also with axios in the
   README. *)
(* TODO Note that form requires a session to be active, for the CSRF
   checking. *)

(* TODO Get rid of this separate call. However, it means requests must become
   more mutable, in particular there needs to be extensible mutability for body
   handling, which is already mutable. *)
(* val begin_upload : request -> request *)

(** {2 Upload} *)

type part = [
  | `Files of (string * string) list
  | `Value of string
]
(** Field values of an upload form, [<form enctype="multipart/form-data">]. See
    {!Dream.multipart} and example
    {{:https://github.com/aantron/dream/tree/master/example/g-upload#files}
    [g-upload]}.

    - [`Files] is a list of filename-content pairs.
    - [`Value] is the value of an ordinary form field.

    Parts are then paired with field names by {!Dream.multipart}, making a
    [(string * part) list].

    For example, if the form has [<input name="foo" type="file" multiple>], and
    the user selects multiple files, the received field name and {!type-part}
    will be

    {[
      ("foo", `Files [
        ("file1", "data1");
        ("file2", "data2");
      ])
    ]} *)

val multipart : request -> (string * part) list form_result promise
(** Like {!Dream.form}, but also reads files, and [Content-Type:] must be
    [multipart/form-data]. The [<form>] tag and CSRF token can be generated in a
    template with

    {[
      <%s! Dream.Tag.form ~action:"/" ~enctype:`Multipart_form_data request %>
    ]}

    See {!Dream.Tag.form}, section {!section-templates}, and example
    {{:https://github.com/aantron/dream/tree/master/example/g-upload#files}
    [g-upload]}.

    {!Dream.multipart} reads entire files into memory, so it is only suitable
    for prototyping, or with yet-to-be-added file size and count limits. See
    {!Dream.val-upload} below for a streaming version. *)

(** {2 Streaming upload} *)

type upload_event = [
  | `File of string * string
  | `Field of string * string
  | `Done
  | `Wrong_content_type
]
(** Upload stream events.

    - [`File (field_name, filename)] begins a file in the stream. The web app
      should call {!Dream.val-upload_file} until [None], then call
      {!Dream.val-upload} again.
    - [`Field (field_name, value)] is a complete field. The web app should call
      {!Dream.val-upload} next.
    - [`Done] ends the stream.
    - [`Wrong_content_type] occurs on the first call to {!Dream.val-upload} if
      [Content-Type:] is not [multipart/form-data]. *)

val upload : request -> upload_event promise
(** Retrieves the next upload stream event.

    Does not verify a CSRF token. There are several ways to add CSRF protection
    for an upload stream, including:

    - Generate the form with {!Dream.Tag.form}. Check for
      [`Field ("dream.csrf", token)] during upload and call
      {!Dream.verify_csrf_token}.
    - Use {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData}
      [FormData]} in the client to submit [multipart/form-data] by AJAX, and
      include a custom header. *)

val upload_file : request -> string option promise
(** Retrieves a file chunk. *)

(* TODO upload_bigstring *)

(* TODO Document how errors are reported, how this responds to various
   Content-Types, etc. *)
(* TODO The API should be something like...
val upload : request -> [
  `File of ...
  `Field of ...
  `Done
]
 *)

(** {2 CSRF tokens}

    It's usually not necessary to handle CSRF tokens directly.

    - Form tag generator {!Dream.Tag.form} generates and inserts a CSRF token
      that {!Dream.val-form} and {!Dream.val-multipart} transparently verify.
    - AJAX can be protected from CSRF by {!Dream.origin_referer_check}.

    CSRF functions are exposed for creating custom schemes, and for defense in
    depth purposes. *)

type csrf_result = [
  | `Ok
  | `Expired of float
  | `Wrong_session
  | `Invalid
]
(** CSRF token verification outcomes.

    [`Expired] and [`Wrong_session] can occur in normal usage, when a user's
    form or session expire, respectively. However, they can also indicate
    attacks, including stolen tokens, stolen tokens from other sessions, or
    attempts to use a token from an invalidated pre-session after login.

    [`Invalid] indicates a token with a bad signature, a payload that was not
    generated by Dream, or other serious errors that cannot usually be triggered
    by normal users. [`Invalid] usually corresponds to bugs or attacks.
    [`Invalid] can also occur for very old tokens after old keys are no longer
    in use on the server. *)

(* TODO Guidance on how to transmit and receive the token; links. *)
val csrf_token : ?valid_for:float -> request -> string
(** Returns a fresh CSRF token bound to the given request's and signed with the
    [~secret] given to {!Dream.run}. [~valid_for] is the token's lifetime, in
    seconds. The default value is one hour ([3600.]). Dream uses signed tokens
    that are not stored server-side. *)

val verify_csrf_token : string -> request -> csrf_result promise
(** Checks that the CSRF token is valid for the request's session. *)



(* TODO Need a template control flow example. *)
(** {1 Templates}

    Dream includes a template preprocessor that allows interleaving OCaml and
    HTML in the same file:

    {v
let render message =
  <html>
    <body>
      <p>The message is <b><%s message %></b>!</p>
    </body>
  </html>
    v}

    See example
    {{:https://github.com/aantron/dream/tree/master/example/6-template#files}
    [6-template]}.

    To build the template, add this to [dune]:

    {v
(rule
 (targets template.ml)
 (deps template.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
    v}

    A template begins...

    - {e Implicitly} on a line that starts with [<] and is indented by at least
      one column. The line is part of the template.
    - {e Explicitly} after a line that starts with [%%]. The [%%] line is not
      part of the template.

    A [%%] line can also be used to set template options. The only option
    supported presently is [%% response] for streaming the template using
    {!Dream.write}, to a {!type-response} that is in scope. This is shown in
    example
    {{:https://github.com/aantron/dream/tree/master/example/w-template-stream#files}
    [w-template-stream]}.

    A template ends...

    - {e Implicitly}, when the indentation level is less than that of the
      beginning line.
    - {e Explicitly} on a line that starts with another [%%].

    Everything outside a template is ordinary OCaml code.

    OCaml code can also be inserted into a template:

    - [<%s code %>] expects [code] to evaluate to a [string], and inserts the
      [string] into the template.
    - A line that begins with [%] in the first column is OCaml code inside the
      template. Its value is not inserted into the template. Indeed, it can be
      fragments of control-flow constructs.
    - [<% code %>] is a variant of [%] that can be used for short snippets
      within template lines.

    The [s] in [<%s code %>] is actually a
    {{:https://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html}
    Printf}-style format specification. So, for example, one can print two hex
    digits using [<%02X code %>].

    [<%s code %>] automatically escapes the result of [code] using
    {!Dream.html_escape}. This can be suppressed with [!]. [<%s! code %>] prints
    the result of [code] literally. {!Dream.html_escape} is only safe for use in
    HTML text and quoted attribute values. It does not offer XSS protection in
    unquoted attribute values, CSS in [<style>] tags, or literal JavaScript in
    [<script>] tags.

    The preprocessor will output Reason code if the template source file's
    extension is [.re], for example [template.eml.re]. See examples
    {{:https://github.com/aantron/dream/tree/master/example/r-template#files}
    [r-template]} and
    {{:https://github.com/aantron/dream/tree/master/example/r-template-stream#files}
    [r-template-stream]}. *)
(* TODO Open out-links in a new tab. *)

(* TODO Replace the module by the docs of form, and make all links point to
   here. *)
(* TODO Site/subsite prefix from request. *)
module Tag :
sig
  val form :
    ?enctype:[ `Multipart_form_data ] -> action:string -> request -> string
end
(** See [_tag_form]. *)

val _tag_form :
  ?enctype:[ `Multipart_form_data ] -> action:string -> request -> string
(** Generates a [<form>] tag and an [<input>] tag with a CSRF token, suitable
    for use with {!Dream.val-form} and {!Dream.val-multipart}. For example, in
    a template,

    {[
      <%s! Dream.Tag.form ~action:"/" request %>
        <input name="my.field">
      </form>
    ]}

    expands to

    {[
      <form method="POST" action="/">
        <input name="dream.csrf" type="hidden" value="some-csrf-token">
        <input name="my.field">
      </form>
    ]}

    Pass [~enctype:`Multipart_form_data] for a file upload form. *)



(* TODO Move logger to Logging, echo to testing. *)
(** {1 Middleware}

    Interesting built-in middlewares are scattered throughout the various
    sections of these docs, according to where they are relevant. This section
    contains only generic middleware combinators. *)

val identity : middleware
(** Does nothing but call its inner handler. *)

val pipeline : middleware list -> middleware
(** Combines a sequence of middlewares into one, such that these two lines are
    equivalent:

    {v
Dream.pipeline [middleware_1; middleware_2; ...; middleware_n] @@ handler
    v}
    {v
           middleware_1 @@ middleware_2 @@ ... @@ middleware_n @@ handler
    v} *)
(* TODO This code block is highlighted as CSS. Get a better
   highlight.pack.js. No, will need a tokenizer probably. *)



(* TODO Do anchors actually work for fresh visits? *)
(** {1 Routing} *)

val router : route list -> middleware
(** Creates a router. Besides interpreting routes, a router is a middleware
    which calls its next handler if none of its routes match the request. Route
    components starting with [:] are parameters, which can be retrieved with
    {!Dream.param}. See example
    {{:https://github.com/aantron/dream/tree/master/example/3-router#files}
    [3-router]}.

    {[
      let () =
        Dream.run
        @@ Dream.router [
          Dream.get "/echo/:word" @@ fun request ->
            Dream.respond (Dream.param "word" request);
        ]
        @@ Dream.not_found
    ]}

    {!Dream.scope} is the main form of site composition. However, Dream also
    supports full subsites with [*]:

    {[
      let () =
        Dream.run
        @@ Dream.router {
          Dream.get "/static/*" @@ Dream.static "www/static";
        }
        @@ Dream.not_found
    ]}

    [*] causes the request's path to be trimmed by the route prefix, and the
    request's prefix to be extended by it. It is mainly useful for “mounting”
    {!Dream.static} as a subsite.

    It can also be used as an escape hatch to convert a handler, which may
    include its own router, into a subsite. However, it is better to compose
    sites with routes and {!Dream.scope} rather than opaque handlers and [*],
    because, in the future, it may be possible to query routes for site
    structure metadata. *)

(* :((( *)
val param : string -> request -> string
(** Retrieves the path parameter. If it is missing, {!Dream.param} raises an
    exception — the program is buggy. *)

val scope : string -> middleware list -> route list -> route
(** Groups routes under a common path prefix and middlewares. Middlewares are
    run only if a route matches.

    {[
      Dream.scope "/api" [Dream.origin_referer_check] [
        Dream.get  "/widget" get_widget_handler;
        Dream.post "/widget" set_widget_handler;
      ]
    ]}

    To prefix routes without applying any more middleware, use the empty list:

    {[
      Dream.scope "/api" [] [
        (* ...routes... *)
      ]
    ]}

    To apply middleware without prefixing the routes, use ["/"]:

    {[
      Dream.scope "/" [Dream.origin_referer_check] [
        (* ...routes... *)
      ]
    ]}

    Scopes can be nested. *)

val get : string -> handler -> route
(** Forwards [`GET] requests for the given path to the handler.

    {[
      Dream.get "/home" home_template
    ]} *)

val post : string -> handler -> route
val put : string -> handler -> route
val delete : string -> handler -> route
val head : string -> handler -> route
val connect : string -> handler -> route
val options : string -> handler -> route
val trace : string -> handler -> route
val patch : string -> handler -> route
(** Like {!Dream.get}, but for each of the other {{!type-method_} methods}. *)

val not_found : handler
(** Always responds with [404 Not Found]. *)

val static :
  ?handler:(string -> string -> handler) ->
    string -> handler
(** Serves static files from the given local path. See example
    {{:https://github.com/aantron/dream/tree/master/example/f-static#files}
    [f-static]}.

    {[
      let () =
        Dream.run
        @@ Dream.router {
          Dream.get "/static/*" @@ Dream.static "www/static";
        }
        @@ Dream.not_found
    ]}

    [Dream.static local_path] checks that the request [path] is relative and
    contains no parent directory references. It then calls [~handler local_root
    path request]. The default handler responds with a file at [local_root/path]
    in the file system, or [404 Not Found] if the file does not exist.

    Pass [~handler] to implement any other behavior, including serving files
    from memory. [~handler] can set headers on its response, including [ETag:]

    If checks on [path] fail, {!Dream.static} responds with [404 Not Found]. *)

(* TODO Document.

Dream.get "static/*" (Dream.static "static")

Now with Content-Type guessing.
 *)
(* TODO Expose default static handlers. At least the FS one. Should probably
   also add a crunch-based handler, because it can send nice etags. *)



(* TODO Expose typed sessions in the main API? *)
(* TODO Link out to docs of Dream.Session module. Actually, the module needs to
   be included here with its whole API. *)
(* TODO The session manager may need to interact with AJAX in other ways. *)
(** {1 Sessions}

    TODO:

    - Default Dream sessions store [string -> string] dictionaries.
    - There are multiple back ends, storing sessions in memory (for
      development), in a database, stateless in cookies, etc.
    - This is all actually a specialization of Dream's typed sessions, which are
      quite flexible. A user can write their own back ends and use sessions of
      any type. Link to the easy examples. Link to [Dream.Session].
    - Ultimately, if this is not customizable enough, one can write their own
      session back end. If still wishing to use the other parts of Dream that
      depend on sessions, all those parts are configurable by provinding
      callback functions to use any other session setup.
    - What do sessions have? App data (the dictionary), but also a secret key,
      log-friendly id, expiration time.
    - Mention security.
    - Mention pre-sessions.
    - Note that session middleware doesn't communicate with the client
      itself.
    - Recommend using only under HTTPS. *)

val sessions_in_memory : middleware
(** Stores session data server-side in memory, i.e. without persistence. Passes
    session keys to clients in cookies. Session data is lost when the server
    process exits. This session middleware is suitable for prototyping, because
    it has no persistence or key management requirements. *)
(* TODO Protocol error on HTTS+(HTTP2)? *)

val session : string -> request -> string option
(** Retrieves the value with the given key in the request's session, if the
    value is present. *)

val set_session : string -> string -> request -> unit promise
(** [Dream.set_session key value request] sets a value in the request's session.
    If there is an existing binding, it is replaced. The data store used by the
    session middleware may immediately commit the value to storage, so this
    function returns a promise. *)

val all_session_values : request -> (string * string) list
(** Retrieves the full session dictionary. *)

val invalidate_session : request -> unit promise
(** Invalidates the given session, replacing it with a fresh one (a new
    pre-session with an empty dictionary). The session store is likely to update
    storage while creating the new session, so this function returns a
    promise. *)

val session_key : request -> string
(** Evaluates to the request's session's key. This is a secret value that is
    used to identify a client. *)

val session_id : request -> string
(** Evaluates to the request's session's identifier. This value is not secret;
    it is suitable for printing to logs for tracing session lifetime. *)

val session_expires_at : request -> int64
(** Evaluates to the time at which the session will expire. *)



(* TODO Open an issue about frames. *)
(* TODO Links to MDN, RFCs? examples? *)
(** {1 WebSockets} *)

type websocket
(** A WebSocket connection. See {{:https://tools.ietf.org/html/rfc6455} RFC
    6455} and
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API} MDN}. *)

val websocket : (websocket -> unit promise) -> response promise
(** Creates a fresh [101 Switching Protocols] response. Once this response is
    returned to Dream's HTTP layer, the callback is passed a new {!websocket},
    and the application can begin using it. See example
    {{:https://github.com/aantron/dream/tree/master/example/k-websocket#files}
    [k-websocket]}.

    {[
      let my_handler = fun request ->
        Dream.websocket (fun websocket ->
          let%lwt () = Dream.send "Hello, world!" websocket in
          Dream.close_websocket websocket);
    ]} *)

val send : ?kind:[ `Text | `Binary ] -> string -> websocket -> unit promise
(** Sends a single message. The WebSocket is ready another message when the
    promise resolves.

    With [~kind:`Text], the default, the message is interpreted as a UTF-8
    string. The client will receive it transcoded to JavaScript's UTF-16-like
    representation.

    With [~kind:`Binary], the message will be received unmodified, as either a
    [Blob] or an [ArrayBuffer]. See
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/binaryType}
    MDN [WebSocket.binaryType]}. *)

val receive : websocket -> string option promise
(** Retrieves a message. If the WebSocket is closed before a complete message
    arrives, the result is [None]. *)

val close_websocket : websocket -> unit promise
(** Closes the WebSocket. *)



(** {1 GraphQL} *)

val graphql : (request -> 'a promise) -> 'a Graphql_lwt.Schema.schema -> handler
(* TODO Any neat way to hide the context-maker for super basic usage? *)
(* TODO Either that, or give it a name so that it's clearer. *)



(* TODO The TOC highlighting JS does not do well on short sections; it detects
   a next one. Needs to be anchor-target-sensitive. *)
(** {1 SQL} *)

(* TODO Expose the lower-level helpers. *)
(* type sql_pool = Caqti_lwt.Pool.t *)

(* val connect_to_sql : ?pool_size:int -> string -> sql_pool Lwt.t *)

(* val use_sql : (sql_connection -> 'a Lwt.t) -> sql_pool -> 'a Lwt.t *)

(* val sql_pool : ?size:int -> string -> middleware *)

(* val sql : (Caqti_lwt.connection -> 'a Lwt.t) -> request -> 'a Lwt.t *)
(* TODO This should fit very neatly in examples. *)

(* val sql_stream :
  (Caqti_lwt.connection -> unit Lwt.t) -> request -> response Lwt.t *)
(* TODO This function eeds the response as argument. *)


(** {1 Logging} *)

val logger : middleware
(** Logs incoming requests, times them, and prints timing information when the
    next handler has returned a response. Time spent logging is included in the
    timings. *)

val log : ('a, Format.formatter, unit, unit) format4 -> 'a
(** [Dream.log format arguments] formats [arguments] and writes them to the log.
    Disregard the obfuscated type: the first argument, [format], is a format
    string as described in the standard library modules
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html#VALfprintf}
    [Printf]} and
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Format.html#VALfprintf}
    [Format]}, and the rest of the arguments are determined by the format
    string. For example:

    {[
      Dream.log "Counter is now: %i" counter;
      Dream.log "Client: %s" (Dream.client request);
    ]} *)

type ('a, 'b) conditional_log =
  ((?request:request ->
   ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b) ->
    unit
(** See {!Dream.val-error} for usage. This type has to be defined, but its
    definition is largely illegible. *)

type log_level = [
  | `Error
  | `Warning
  | `Info
  | `Debug
]
(** Log levels, in order from most urgent to least. *)

val error : ('a, unit) conditional_log
(** Formats a message and writes it to the log at level [`Error]. The inner
    formatting function is called only if the {{!initialize_log} current log
    level} is [`Error] or higher. This scheme is based on the
    {{:https://erratique.ch/software/logs/doc/Logs/index.html} Logs} library.

    {[
      Dream.error ~request (fun log -> log "My message, details: %s" details);
    ]}

    Pass the optional argument [~request] to [Dream.error] to help it associate
    the message with a specific request. If not passed, the logging back end
    will try to guess the request. This usually works, but may be inaccurate in
    some cases. *)

val warning : ('a, unit) conditional_log
val info : ('a, unit) conditional_log
val debug : ('a, unit) conditional_log
(** Like {!Dream.val-error}, but for each of the other {{!log_level} log
    levels}. *)

type sub_log = {
  error : 'a. ('a, unit) conditional_log;
  warning : 'a. ('a, unit) conditional_log;
  info : 'a. ('a, unit) conditional_log;
  debug : 'a. ('a, unit) conditional_log;
}
(** Sub-logs. See {!Dream.val-sub_log} right below. *)

(* TODO Show examples with calls at different types/format strings. *)
(* TODO How to change levels of individual logs. *)
val sub_log : string -> sub_log
(** Creates a new sub-log with the given name. For example,

    {[
      let log = Dream.sub_log "myapp.ajax"
    ]}

    Creates a logger that can be used like {!Dream.val-error} and the other
    default loggers, but prefixes ["myapp.ajax"] to each log message:

    {[
      log.error (fun log -> log ~request "Validation failed")
    ]} *)

val initialize_log :
  ?backtraces:bool ->
  ?async_exception_hook:bool ->
  ?level:log_level ->
  ?enable:bool ->
    unit -> unit
(** Dream does not initialize its logging back end on program start. This is
    meant to allow a Dream web application to be linked into a larger binary as
    a subcommand, without affecting the runtime of that larger binary in any
    way. Instead, this function, [Dream.initialize_log], is called internally by
    the various Dream loggers (such as {!Dream.log}) the first time they are
    used. You can also call this function explicitly during program
    initialization, before using the loggers, in order to configure the back end
    or disable it completely.

    [~backtraces:true], the default, causes Dream to call
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printexc.html#VALrecord_backtrace}
    [Printexc.record_backtrace]}, which makes exception backtraces available
    when logging exceptions.

    [~async_exception_hook:true], the default, causes Dream to set
    {{:https://ocsigen.org/lwt/latest/api/Lwt#VALasync_exception_hook}
    [Lwt.async_exception_hook]} so as to forward all asynchronous exceptions to
    the logger, and not terminate the process.

    [~level] sets the log level threshould for the entire binary. The default is
    [`Info].

    [~enable:false] disables Dream logging completely. This can help sanitize
    output for testing. *)



(** {1:error_page Error page}

    Dream passes all errors to a single error handler that is immediately above
    the HTTP server layer. This includes:

    - Exceptions raised by the application, and rejected promises.
    - [4xx] and [5xx] responses returned by the application.
    - Protocol-level errors, such as TLS handshake failures and malformed HTTP
      requests.

    This allows you to customize all of your application's error handling in one
    place.

    The easiest way to customize is to call {!Dream.error_template} to create a
    customized version of the default error handler. It will log errors like the
    default handler, and, when a response is possible, it will call your
    template to generate the response. Pass this customized error handler to
    {!Dream.run}.

    The default error handler used by {!Dream.run} uses a default template,
    which generates responses with no body. This prevents leakage of strings, in
    particular unlocalized strings in any natural language.

    If you want full control over error handling, including replacing the
    logging done by the default handler, you can define a {!Dream.error_handler}
    directly, to process all values of type {!Dream.type-error}. *)

type error = {
  condition : [
    | `Response of response
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
  severity : log_level;
  debug : bool;
  will_send_response : bool;
}
(** Generalized Dream errors.

    [condition] describes the error itself. [`Response] means the error is a
    [4xx] or [5xx] response. [`String] and [`Exn] should be self-explanatory.
    The default error handler logs error strings and exceptions, but does not
    log error responses, because they have been generated explicitly by the
    application. They are typically already noted by {!Dream.logger}, if the
    logger is being used.

    [layer] is [`App] if the error was generated by the application, and one of
    the other values if the error was generated by one of the protocol state
    machines inside {!Dream.run}. For example, in case the client sends an
    HTTP/1.1 request so malformed that it can't be parsed at all, an error with
    [layer = `HTTP] will be generated. The default error handler uses the layer
    to prepend helpful strings to its log messages.

    [caused_by] indicates which side likely caused the error. Server errors
    suggest bugs, and correspond to [5xx] responses. Client errors can be noise,
    or indicate buggy clients or attempted attacks. Client errors correspond to
    [4xx] responses.

    [request] is a request associated with the error, if there is one. A request
    might not be available if, for example, the error is a failure to parse an
    HTTP/1.1 request at all, or perform a TLS handshake. In case of a WebSocket
    error, the request is the client's original request to establish the
    WebSocket connection.

    [response] is either a response that was generated by the application, or a
    suggested response generated by the context where the error occurred. In
    case of a WebSocket error, the response is the application's original
    connection agreement response created by {!Dream.val-websocket}.

    [client] is the client's address, if available. For example,
    [127.0.0.1:56001].

    [severity] is the likely severity of the error. This is usually [`Error] for
    server errors, and [`Warning] for client errors. The default error handler
    logs the error at level [severity].

    [debug] is [true] if debugging is enabled on the server. If so, the default
    error handler gathers various fields from any available request, formats the
    error condition, and passes the resulting string to the template. The
    default template shows this string in its repsonse, instead of returning a
    response with no body.

    [will_send_response] is [true] in error contexts where Dream will still send
    a response. A typical example is when there is an application exception —
    Dream will still send at least an empty [500 Internal Server Error], if not
    changed by the template. Conversely, in case of a TLS handshake failure,
    there is no client to send an HTTP response to, so no response will be sent.
    In this latter case, the default error handler does not call the template at
    all. *)

type error_handler = error -> response option promise
(** Error handlers generate responses for errors with
    [will_send_response = true]. They typically also log errors along the way.
    See {!Dream.type-error}. You can define your own freely if you need to —
    it's a bare function.

    If an error handler raises an exception, rejects its result promise, or
    returns [None] when [will_send_response = true] in the error it is handling,
    this is a double fault. Dream prints an emergency message to one of its
    sub-logs, and, depending on the context, does nothing else, sends an empty
    [500 Internal Server Error], or closes a connection.

    The behavior of Dream's built-in error handler is described at
    {!Dream.type-error}. *)

(* TODO Should sanitize template output here or set to text/plain to prevent XSS
   against developer. *)
val error_template :
  (string option -> response -> response promise) -> error_handler
(** Customizes the default error handler by specifying a template.
    {[
      let my_error_handler =
        Dream.error_template (fun ~debug_dump response ->
          let body =
            match debug_dump with
            | Some string -> string
            | None -> Dream.status_to_string (Dream.status response)
          in

          response
          |> Dream.with_body body
          |> Lwt.return)
    ]}

    [response] is a response suggested by the error context. Its most
    interseting field is {!Dream.val-status}, which is often used in pretty
    templates to generate the main error text.

    If the error is a [4xx] or [5xx] response generated by your application, it
    will be passed to the template in [response]. Otherwise, [response] is
    typically an empty response pre-filled with status [400 Bad Request] or [500
    Internal Server Error], according to whether the underlying error was likely
    caused by the client or the server. The error template will typically
    customize [response]; however, it can also ignore the response and generate
    a fresh one.

    [~debug_dump] will be [Some info] when debugging is enabled for the
    application with [Dream.run ~debug:true]. [info] is a string containing an
    error description, stack trace, request state, and other information.

    Note that not all contexts are capable of using all fields of the response
    returned by the template. For example, some HTTP contexts are hardcoded
    upstream to send either [400 Bad Request] or [500 Internal Server Error],
    regardless of the status returned by the template. They still send the
    template's body, however.

    Raising an exception or rejecting the final promise in the template may
    cause an empty [500 Internal Server Error] to be sent to the client, if the
    context requires it. See {!Dream.error_handler}. *)



(** {1 Variables}

    Dream provides two variable scopes for writing middlewares:

    - Per-message (“local”) variables.
    - Per-server (“global”) variables.

    Variables can be used to implicitly pass values from middlewares to wrapped
    handlers. For example, Dream assigns each request an id, which is stored in
    a “local” (request) variable. {!Dream.request_id} can then be called on that
    request; it internally reads that variable. *)

type 'a local
(** Per-message variable. *)

type 'a global
(** Per-server variable. *)

val new_local : ?debug:('a -> string * string) -> unit -> 'a local
(** Declares a fresh variable of type ['a] in all messages. In each message, the
    variable is initially unset. The optional [~debug] parameter provides a
    function that converts the variable's value to a pair of [key, value]
    strings. This causes the variable to be included in debug info by the
    default error handler when debugging is enabled. *)
(* TODO Provide a way to query the local for its name, which can be used by
   middlewares for generating nicer error messages when a local is not found.
   But then the metadata has to become string * 'a -> string, or it can be
   split into to a separate name and converter to make it even easier to deal
   with. *)

val local : 'a local -> 'b message -> 'a option
(** Retrieves the value of the given per-message variable, if it is set. *)

val with_local : 'a local -> 'a -> 'b message -> 'b message
(** Creates a new message by setting or replacing the variable with the given
    value. *)

val new_global : ?debug:('a -> string * string) -> (unit -> 'a) -> 'a global
(** [Dream.new_global initializer] declares a fresh variable of type ['a] in all
    servers. The first time the variable is accessed, [ititializer ()] is called
    to create its initial value.

    Global variables cannot themselves be changed, because the server-wide
    application context is shared between all requests. This means that global
    variables are typically refs or other mutable data structures, such as hash
    tables — as is often the case with regular OCaml globals. *)

val global : 'a global -> request -> 'a
(** Retrieves the value of the given per-server variable. *)



(** {1 HTTP} *)

(* TODO Document adjust_terminal. Or maybe move it to initialize_log? *)
val run :
  ?interface:string ->
  ?port:int ->
  ?stop:unit promise ->
  ?debug:bool ->
  ?error_handler:error_handler ->
  ?secret:string ->
  ?prefix:string ->
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
  ?greeting:bool ->
  ?stop_on_input:bool ->
  ?graceful_stop:bool ->
  ?adjust_terminal:bool ->
    handler -> unit
(** [Dream.run handler] runs the web application represented by [handler] as a
    web server, by default at {{:http://localhost:8080}
    http://localhost:8080}. All other arguments are optional. The server runs
    until there is a newline on STDIN. In practice, this means you can stop the
    server by pressing ENTER.

    This function calls {{:https://ocsigen.org/lwt/latest/api/Lwt_main#VALrun}
    [Lwt_main.run]} internally, and so is intended to be used as the main loop
    of a program. {!Dream.serve} is a version of [Dream.run] that does not call
    [Lwt_main.run]. Indeed, [Dream.run] is a wrapper around {!Dream.serve}.

    [~interface] and [~port] specify the network interface and port to listen
    on. Use [~interface:"0.0.0.0"] to bind to all interfaces. The default values
    are ["localhost"] and [8080].

    [~stop] is a promise that causes the server to stop when it resolves. The
    server stops accepting new requests. Requests that have already entered the
    web application continue to be processed. The default value is a promise
    that never resolves. However, see also [~stop_on_input].

    [~debug:true] enables debug information in {{!error_page} error templates}.
    It is [false] by default, to help prevent accidental deployment with
    debugging on.

    [~error_handler] receives all errors, including exceptions, [4xx] and [5xx]
    responses, and protocol-level errors. See {{!error_page} Error page} for
    details. The default handler logs all errors, and sends empty responses, to
    avoid accidental leakage of unlocalized strings to the client.

    [~secret] is a key to be used for cryptographic operations. In particular,
    it heavily used for CSRF tokens.

    [~prefix] is a site prefix for applications that are not running at the root
    ([/]) of their domain, and receiving requests with the prefix included in
    the target. A top-most router in the application will check that each
    request has the expected path prefix, and remove it before routing. This
    allows the application's routes to assume that the root is ["/"]. This is
    the first “hop” in Dream's composable routing. The default value is [""]: no
    prefix.

    [~https] enables HTTPS. The default value is [`No]. The other options select
    the TLS library. If using [~https:`OpenSSL], you should install opam package
    [lwt_ssl]. If using [~https:`OCaml_TLS], you should install opam package
    [tls]. In both cases, you should also specify [~certificate_file] and
    [~key_file]. However, for development, Dream includes a compiled-in
    localhost certificate that is completely insecure. It allows testing HTTPS
    without obtaining or generating your own certificates, so using only the
    [~https] argument. The development certificate can be found in
    {{:https://github.com/aantron/dream/tree/master/src/certificate}
    src/certificate/} in the Dream source code, and reviewed with

    {[
      openssl x509 -in localhost.crt -text -noout
    ]}

    Enabling HTTPS also enables transparent upgrading of connections to HTTP/2,
    if the client requests it. HTTP/2 without HTTPS (known as h2c) is not
    supported by Dream at the moment — but it is also not supported by most
    browsers.

    [~certificate_file] and [~key_file] specify the certificate and key file,
    respectively, when using [~https]. They are not required for development,
    but are required for production. Dream will write a warning to the log if
    you are using [~https], don't provide [~certificate_file] and [~key_file],
    and [~interface] is not ["localhost"].

    [~certificate_string] and [~key_string] allow specifying a certificate and
    key from memory. Dream's handling of these is completely insecure at the
    moment: they are written to temporary files. These arguments are only
    intended for development, for use with an insecure certificate, as a
    fallback in case there is a problem with Dream's built-in development
    certificate, and it is inconvenient to generate separate files.

    The last three arguments, [?greeting], [?stop_on_input], and
    [?graceful_stop] can be used to gradually disable convenience features of
    [Dream.run]. Once all three are disabled, you may want to switch to
    using {!Dream.serve}.

    [~greeting:false] disables the start-up log message that prints a link to
    the web application.

    [~stop_on_input:false] disables stopping the server on input on STDIN.

    [~graceful_stop:false] disables waiting for one second after stop, before
    exiting from [Dream.run], which is done to let already-running request
    handlers complete. *)
(* TODO Consider setting terminal options by default from this function, so that
   they don't have to be set in Makefiles. *)
(* TODO Split up ~https into ~https:true and a separate library choice, which
   default probably to OpenSSL. *)
(* TODO Option for disabling built-in middleware. *)

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit promise ->
  ?debug:bool ->
  ?error_handler:error_handler ->
  ?secret:string ->
  ?prefix:string ->
  ?https:[ `No | `OpenSSL | `OCaml_TLS ] ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?certificate_string:string ->
  ?key_string:string ->
    handler -> unit promise
(** Same as {!Dream.run}, but returns a promise that does not resolve until the
    server stops listening, instead of calling
    {{:https://ocsigen.org/lwt/latest/api/Lwt_main#VALrun} [Lwt_main.run]} on
    it, and lacks some of the higher-level conveniences such as monitoring STDIN
    and graceful exit.

    This function is meant for integrating Dream applications into larger
    programs that have their own procedures for starting and stopping the web
    server.

    All arguments have the same meanings as they have in {!Dream.run}. *)

(* TODO Document middleware as built-in. Link to customizzation of built-in
   middleware. *)
val content_length : middleware
(* TODO Transfer-encoding chunked. *)

val catch : (error -> response promise) -> middleware
(* TODO Move the error handler into the app. *)

val assign_request_id : middleware

val chop_site_prefix : string -> middleware
(* TODO Get the site prefix from the app. *)

(* TODO Note about stability of built-in middleware during alpha. *)



(* TODO Add hex encoding. Add secret generation example. *)
(** {1:web_formats Web formats} *)

val html_escape : string -> string
(** Escapes a string so that it is suitable for use as text inside HTML
    elements, and quoted attribute values. *)
(* TODO OWASP links. *)

val to_base64url : string -> string
(** Converts the given string its base64url encoding, as specified in
    {{:https://tools.ietf.org/html/rfc4648#section-5} RFC 4648 §5}, using a
    web-safe alphabet and no padding. The resulting string can be used without
    escaping in URLs, form data, cookies, HTML content, attributes, and
    JavaScript code. For more options, see the
    {{:https://mirage.github.io/ocaml-base64/base64/Base64/index.html} Base64}
    library.*)

val from_base64url : string -> (string, string) result
(** Inverse of {!Dream.to_base64url}. *)

val to_form_urlencoded : (string * string) list -> string
(** Inverse of {!Dream.from_form_urlencoded}. *)
(* TODO DOC Does this do any escaping? *)

val from_form_urlencoded : string -> (string * string) list
(** Converts form data or a query string from
    [application/x-www-form-urlencoded] format to a list of name-value pairs.
    See {{:https://tools.ietf.org/html/rfc1866#section-8.2.1} RFC 1866
    §8.2.1}. *)

val from_cookie : string -> (string * string) list
(** Converts a [Cookie:] header value to key-value pairs. See
    {{:https://tools.ietf.org/html/rfc6265#section-4.2.1} RFC 6265 §4.2.1}. *)
(* TODO DOC Do we decode? NO. *)

(* TODO Replace all time by floats. *)
val to_set_cookie :
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[ `Strict | `Lax | `None ] ->
    string -> string -> string
(** [Dream.to_set_cookie name value] formats a [Set-Cookie:] header value. The
    optional arguments correspond to the attributes specified in
    {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07} RFC
    6265bis}:

    [~expires] sets the expiration date of the cookie. It is a time value in
    seconds, like returned by
    {{:https://caml.inria.fr/pub/docs/manual-ocaml/libref/Unix.html#VALgettimeofday}
    [Unix.gettimeofday]}. [~max_age] is a time span in seconds. If both are
    given, compliant clients use [~max_age]. If neither is given, a compliant
    client deletes the cookie whenever it considers the client-side session to
    have expired, which typically corresponds to browser close. However, some
    clients persist cookies without [~expires] and [~max_age] indefinitely. In
    general, clients may persist cookies beyond their expiration, or delete them
    before expiration, so web applications should not rely on client-side
    expiration for server state management.

    [~domain] is used to allow clients to send the cookie to subdomains. When
    absent, conformant clients send the cookie only when accessing the cookie's
    origin domain. It is recommended not to use this option.

    [~path]  *)
(* TODO https://tools.ietf.org/html/rfc6265#section-5 *)
(* TODO https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-05
   for same_site. *)
(* TODO No escaping done. *)
(* TODO MDN links. *)
(* TODO requires prettying in the docs. *)
(* TODO ?request argument for fillign stuff from requests. *)
(* TODO bis prefixes. *)
(* TODO Escaping guidelines. *)
(* TODO Sigining and encryption. *)
(* TODO Recommend against running any untrusted app on the same host under a
   different path, on a different port, or on a subdomain. *)

(* val secure_cookie_prefix : string

val host_cookie_prefix : string *)
(* TODO Expose these. *)

(* TODO Warn about message mutability. *)

val from_target : string -> string * string
(** Splits a request target into a path and a query string. *)

val from_target_path : string -> string list
(** Splits the into components string on [/] and percent-decodes each component.
    Empty components are dropped, except for the last. This function does not
    distinguish between absolute and relative paths, and is only meant for
    routes and request targets. So,

    - [Dream.from_path ""] becomes [[]].
    - [Dream.from_path "/"] becomes [[""]].
    - [Dream.from_path "abc"] becomes [["abc"]].
    - [Dream.from_path "abc/"] becomes [["abc"; ""]].
    - [Dream.from_path "/abc"] becomes [["abc"]].
    - [Dream.from_path "a%2Fb"] becomes [["a/b"]].
    - [Dream.from_path "a//b"] becomes [["a"; "b"]].

    This function is not for use on targets, because it does not treat [?]
    specially. See {!Dream.from_target} if the argument string is actually a
    target, and may include a query string. *)

val drop_empty_trailing_path_component : string list -> string list
(** Drops a last [""] if it is in the argument list. This changes the
    representation of path [abc/] to the representation of [abc]. *)



(* TODO Expose some hash functions. *)
(* TODO Expose current time somewhere. *)
(* TODO Should cryptography be before web formats? *)
(** {1 Cryptography} *)

val random : int -> string
(** Generates the given number of bytes using a
    {{:https://github.com/mirage/mirage-crypto} cryptographically secure random
    number generator}. *)
(* TODO Review which TLS protocls are negotiated. *)
(* TODO Support key retirement? *)
(* TODO Key derivation. *)
(* TODO Refuse RC4 in TLS? *)

val encrypt : request -> string -> string

val decrypt : request -> string -> string option

(*
type cipher

type key

val cipher : cipher

val cipher_name : cipher -> string

val decryption_ciphers : cipher list
(* TODO Should this be a ref? *)

val derive_key : cipher -> string -> key

val encrypt : ?request:request -> ?key:key -> string -> string

val decrypt : ?request:request -> ?keys:key list -> string -> string option

val encryption_key : request -> key

val decryption_keys : request -> key list *)
(* TODO Move most of this to a Cipher module. Base API just needs encrypt and
   decrypt given a request. That will also undo the double optional kludge. *)



(** {1 Testing} *)

val request :
  ?client:string ->
  ?method_:method_ ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
    string -> request
(** [Dream.request body] creates a fresh request with the given body for
    testing. The optional arguments set the corresponding {{!requests} request
    fields}. *)

val test : ?prefix:string -> handler -> (request -> response)
(** [Dream.test handler] runs a handler the same way the HTTP server
    ({!Dream.run}) would — assigning it a request id and noting the site root
    prefix, which is used by routers. [Dream.test] calls
    {{:https://ocsigen.org/lwt/latest/api/Lwt_main#VALrun} [Lwt_main.run]}
    internally to await the response, which is why the response returned from
    the test is not wrapped in a promise. If you don't need these facilities,
    you can test [handler] by calling it directly with a request. *)

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

val sort_headers : (string * string) list -> (string * string) list
(** Sorts headers by name. Headers with the same name are not sorted by value or
    otherwise reordered, because order is significant for some headers. See
    {{:https://tools.ietf.org/html/rfc7230#section-3.2.2} RFC 7230 §3.2.2} on
    header order. This function can help sanitize output before comparison. *)

val echo : handler



(* TODO DOC Give people a tip: a basic response needs either content-length or
   connection: close. *)
(* TODO DOC attempt some graphic that shows what getters retrieve what from the
   response. *)
(* TODO DOC meta description. *)
(* TODO DOC Guidance for Dream libraries: publish routes if you have routes, not
   handlers or middlewares. *)
(* TODO DOC Need a syntax highlighter. Highlight.js won't work for templates for
   sure. *)
(* TODO Dream.read_file and Dream.write_file. *)
