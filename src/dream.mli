(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(** {1 Types}

    Dream is built on just five types. The first two are the data types of
    Dream. Both are abstract, even though they appear to have definitions: *)

type request = client message
(** HTTP requests, such as [GET /something HTTP/1.1]. See
    {!section-requests}. *)

and response = server message
(** HTTP responses, such as [200 OK]. See {!section-responses}. *)

(** The remaining three types are for building up Web apps. *)

and handler = request -> response promise
(** Handlers are asynchronous functions from requests to responses. Example
    {{:https://github.com/aantron/dream/tree/master/example/1-hello#files}
    [1-hello]} \[{{:http://dream.as/1-hello} playground}\] shows the simplest
    handler, an anonymous function which we pass to {!Dream.run}. This creates a
    complete Web server! You can also see the Reason version in example
    {{:https://github.com/aantron/dream/tree/master/example/r-hello#files}
    [r-hello]}.

    {[
      let () =
        Dream.run (fun _ ->
          Dream.html "Good morning, world!")
    ]} *)

and middleware = handler -> handler
(** Middlewares are functions that take a {!handler}, and run some code before
    or after — producing a “bigger” handler. Example
    {{:https://github.com/aantron/dream/tree/master/example/2-middleware#files}
    [2-middleware]} inserts the {!Dream.logger} middleware into a Web app:

    {[
      let () =
        Dream.run
        @@ Dream.logger
        @@ fun _ -> Dream.html "Good morning, world!"
    ]}

    Examples
    {{:https://github.com/aantron/dream/tree/master/example/4-counter#files}
    [4-counter]} \[{{:http://dream.as/4-counter} playground}\] and
    {{:https://github.com/aantron/dream/tree/master/example/5-promise#files}
    [5-promise]} show user-defined middlewares:

    {[
      let count_requests inner_handler request =
        count := !count + 1;
        inner_handler request
    ]}

    In case you are wondering why the example middleware [count_requests] takes
    two arguments, while the type says it should take only one, it's because:

    {[
      middleware
        = handler -> handler
        = handler -> (request -> response promise)
        = handler -> request -> response promise
    ]} *)

and route
(** Routes tell {!Dream.router} which handler to select for each request. See
    {!section-routing} and example
    {{:https://github.com/aantron/dream/tree/master/example/3-router#files}
    [3-router]} \[{{:http://dream.as/3-router/echo/foo} playground}\]. Routes
    are created by helpers such as {!Dream.get} and {!Dream.scope}:

    {[
      Dream.router [
        Dream.scope "/admin" [Dream.memory_sessions] [
          Dream.get "/" admin_handler;
          Dream.get "/logout" admin_logout_handler;
        ];
      ]
    ]} *)

(** {2 Algebra}

    The three handler-related types have a vaguely algebraic interpretation:

    - Each literal {!handler} is an atom.
    - {!type-middleware} is for sequential composition (product-like).
      {!Dream.no_middleware} is {b 1}.
    - {!type-route} is for alternative composition (sum-like). {!Dream.no_route}
      is {b 0}.

    {!Dream.scope} implements a left distributive law, making Dream a ring-like
    structure. *)

(** {2 Helpers} *)

and 'a message = 'a Dream_pure.Message.message
(** ['a message], pronounced “any message,” allows some functions to take either
    {!type-request} or {!type-response} as arguments, because both are defined
    in terms of ['a message]. For example, in {!section-headers}:

    {[
      val Dream.header : string -> 'a message -> string option
    ]} *)

and client = Dream_pure.Message.client
and server = Dream_pure.Message.server
(** Type parameters for {!message} for {!type-request} and {!type-response},
    respectively. These are “phantom” types. They have no meaning other than
    they are different from each other. Dream only ever creates [client message]
    and [server message]. [client] and [server] are never mentioned again in the
    docs. *)
(* TODO These docs need to be clarified. *)
(* TODO Hide all the Dream_pure type equalities. *)

and 'a promise = 'a Lwt.t
(** Dream uses {{:https://github.com/ocsigen/lwt} Lwt} for promises and
    asynchronous I/O. See example
    {{:https://github.com/aantron/dream/tree/master/example/5-promise#files}
    [5-promise]} \[{{:http://dream.as/5-promise} playground}\].

    Use [raise] to reject promises. If you are writing a library, you may prefer
    using
    {{:https://github.com/ocsigen/lwt/blob/9943ba77a5508feaea5e1fb60b011db4179f9c61/src/core/lwt.mli#L459}
    [Lwt.fail]} in some places, in order to avoid clobbering your user's current
    exception backtrace — though, in most cases, you should still extend it with
    [raise] and [let%lwt], instead. *)



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

val method_to_string : [< method_ ] -> string
(** Evaluates to a string representation of the given method. For example,
    [`GET] is converted to ["GET"]. *)

val string_to_method : string -> method_
(** Evaluates to the {!type-method_} corresponding to the given method
    string. *)

val methods_equal : [< method_ ] -> [< method_ ] -> bool
(** Compares two methods, such that equal methods are detected even if one is
    represented as a string. For example,

    {[
      Dream.methods_equal `GET (`Method "GET") = true
    ]} *)

val normalize_method : [< method_ ] -> method_
(** Converts methods represented as strings to variants. Methods generated by
    Dream are always normalized.

    {[
      Dream.normalize_method (`Method "GET") = `GET
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

val status_to_string : [< status ] -> string
(** Evaluates to a string representation of the given status. For example,
    [`Not_Found] and [`Status 404] are both converted to ["Not Found"]. Numbers
    are used for unknown status codes. For example, [`Status 567] is converted
    to ["567"]. *)

val status_to_reason : [< status ] -> string option
(** Converts known status codes to their string representations. Evaluates to
    [None] for unknown status codes. *)

val status_to_int : [< status ] -> int
(** Evaluates to the numeric value of the given status code. *)

val int_to_status : int -> status
(** Evaluates to the symbolic representation of the status code with the given
    number. *)

val is_informational : [< status ] -> bool
(** Evaluates to [true] if the given status is either from type
    {!Dream.informational}, or is in the range [`Status 100] — [`Status 199]. *)

val is_successful : [< status ] -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.successful} and numeric
    codes [2xx]. *)

val is_redirection : [< status ] -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.redirection} and
    numeric codes [3xx]. *)

val is_client_error : [< status ] -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.client_error} and
    numeric codes [4xx]. *)

val is_server_error : [< status ] -> bool
(** Like {!Dream.is_informational}, but for type {!Dream.server_error} and
    numeric codes [5xx]. *)

val status_codes_equal : [< status ] -> [< status ] -> bool
(** Compares two status codes, such that equal codes are detected even if one is
    represented as a number. For example,

    {[
      Dream.status_codes_equal `Not_Found (`Status 404) = true
    ]} *)

val normalize_status : [< status ] -> status
(** Converts status codes represented as numbers to variants. Status codes
    generated by Dream are always normalized.

    {[
      Dream.normalize_status (`Status 404) = `Not_Found
    ]} *)



(** {1 Requests} *)

val client : request -> string
(** Client sending the request. For example, ["127.0.0.1:56001"]. *)

val tls : request -> bool
(** Whether the request was sent over a TLS connection. *)

val method_ : request -> method_
(** Request method. For example, [`GET]. *)

val target : request -> string
(** Request target. For example, ["/foo/bar"]. *)

(**/**)
val prefix : request -> string
(**/**)

(**/**)
val path : request -> string list
[@@ocaml.deprecated
"Router path access is being removed from the API. Comment at
https://github.com/aantron/dream/issues
"]
(** Parsed request path. For example, ["foo"; "bar"]. *)
(* TODO If not removing this, move it to section Routing. *)
(**/**)

val set_client : request -> string -> unit
(** Replaces the client. See {!Dream.val-client}. *)

(**/**)
val with_client : string -> request -> request
[@@ocaml.deprecated
"Use Dream.set_client. See
https://aantron.github.io/dream/#val-set_client
"]
(**/**)

val set_method_ : request -> [< method_ ] -> unit
(** Replaces the method. See {!Dream.type-method_}. *)

(**/**)
val with_method_ : [< method_ ] -> request -> request
[@@ocaml.deprecated
"Use Dream.set_method_. See
https://aantron.github.io/dream/#val-set_method_
"]
(**/**)

(**/**)
val with_path : string list -> request -> request
[@@ocaml.deprecated
"Router path access is being removed from the API. Comment at
https://github.com/aantron/dream/issues
"]
(** Replaces the path. See {!Dream.val-path}. *)
(**/**)

val query : request -> string -> string option
(** First query parameter with the given name. See
    {{:https://tools.ietf.org/html/rfc3986#section-3.4} RFC 3986 §3.4} and
    example
    {{:https://github.com/aantron/dream/tree/master/example/w-query#files}
    [w-query]}. *)

val queries : request -> string -> string list
(** All query parameters with the given name. *)

val all_queries : request -> (string * string) list
(** Entire query string as a name-value list. *)



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

val status : response -> status
(** Response {!type-status}. For example, [`OK]. *)

val set_status : response -> status -> unit
(** Sets the response status. *)



(** {1 Headers} *)

val header : 'a message -> string -> string option
(** First header with the given name. Header names are case-insensitive. See
    {{:https://tools.ietf.org/html/rfc7230#section-3.2} RFC 7230 §3.2} and
    {{:https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers} MDN}. *)

val headers : 'a message -> string -> string list
(** All headers with the given name. *)

val all_headers : 'a message -> (string * string) list
(** Entire header set as name-value list. *)

val has_header : 'a message -> string -> bool
(** Whether the message has a header with the given name. *)

val add_header : 'a message -> string -> string -> unit
(** Appends a header with the given name and value. Does not remove any existing
    headers with the same name. *)
(* TODO Does this fit on one line in the docs now? *)

val drop_header : 'a message -> string -> unit
(** Removes all headers with the given name. *)

val set_header : 'a message -> string -> string -> unit
(** Equivalent to {!Dream.drop_header} followed by {!Dream.add_header}. *)

(**/**)
val with_header : string -> string -> 'a message -> 'a message
[@@ocaml.deprecated
"Use Dream.set_header. See
https://aantron.github.io/dream/#val-with_header
"]
(**/**)



(** {1 Cookies}

    {!Dream.set_cookie} and {!Dream.cookie} are designed for round-tripping
    secure cookies. The most secure settings applicable to the current server
    are inferred automatically. See example
    {{:https://github.com/aantron/dream/tree/master/example/c-cookie#files}
    [c-cookie]} \[{{:http://dream.as/c-cookie} playground}\].

    {[
      Dream.set_cookie response request "my.cookie" "foo"
      Dream.cookie request "my.cookie"
    ]}

    The {!Dream.cookie} call evaluates to [Some "foo"], but the actual cookie
    that is exchanged may look like:

    {v
__Host-my.cookie=AL7NLA8-so3e47uy0R5E2MpEQ0TtTWztdhq5pTEUT7KSFg; \
  Path=/; Secure; HttpOnly; SameSite=Strict
    v}

    {!Dream.set_cookie} has a large number of optional arguments for tweaking
    the inferred security settings. If you use them, pass the same arguments to
    {!Dream.cookie} to automatically undo the result. *)

val set_cookie :
  ?prefix:[< `Host | `Secure ] option ->
  ?encrypt:bool ->
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[< `Strict | `Lax | `None ] option ->
    response -> request -> string -> string -> unit
(** Appends a [Set-Cookie:] header to the {!type-response}. Infers the most
    secure defaults from the {!type-request}.

    {[
      Dream.set_cookie request response "my.cookie" "value"
    ]}

    Use the {!Dream.set_secret} middleware, or the Web app will not be able to
    decrypt cookies from prior starts.

    See example
    {{:https://github.com/aantron/dream/tree/master/example/c-cookie#files}
    [c-cookie]}.

    Most of the optional arguments are for overriding inferred defaults.
    [~expires] and [~max_age] are independently useful. In particular, to delete
    a cookie, use [~expires:0.]

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
      {!Dream.to_base64url}. See {!Dream.set_secret}.
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
      {!Dream.tls} is [true] for the {!type-request}. See
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
    any inference. *)

 val drop_cookie :
   ?prefix:[< `Host | `Secure ] option ->
   ?domain:string ->
   ?path:string option ->
   ?secure:bool ->
   ?http_only:bool ->
   ?same_site:[< `Strict | `Lax | `None ] option ->
     response -> request -> string -> unit
(** Deletes the given cookie.

    This function works by calling {!Dream.set_cookie}, and setting the cookie
    to expire in the past. Pass all the same optional values that you would pass
    to {!Dream.set_cookie} to make sure that the same cookie is deleted. *)

val cookie :
  ?prefix:[< `Host | `Secure ] option ->
  ?decrypt:bool ->
  ?domain:string ->
  ?path:string option ->
  ?secure:bool ->
    request -> string -> string option
(** First cookie with the given name. See example
    {{:https://github.com/aantron/dream/tree/master/example/c-cookie#files}
    [c-cookie]}.

    {[
      Dream.cookie request "my.cookie"
    ]}

    Pass the same optional arguments as to {!Dream.set_cookie} for the same
    cookie. This will allow {!Dream.cookie} to infer the cookie name prefix,
    implementing a transparent cookie round trip with the most secure attributes
    applicable. *)

val all_cookies : request -> (string * string) list
(** All cookies, with raw names and values. *)



(** {1 Bodies} *)

val body : 'a message -> string promise
(** Retrieves the entire body. See example
    {{:https://github.com/aantron/dream/tree/master/example/6-echo#files}
    [6-echo]}. *)

val set_body : 'a message -> string -> unit
(** Replaces the body. *)

(**/**)
val with_body : string -> response -> response
[@@ocaml.deprecated
"Use Dream.set_body. See
https://aantron.github.io/dream/#val-set_body
"]
(**/**)



(** {1 Streams} *)

type stream
(** Gradual reading of request bodies or gradual writing of response bodies. *)

val body_stream : request -> stream
(** A stream that can be used to gradually read the request's body. *)

val stream :
  ?status:[< status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  ?close:bool ->
    (stream -> unit promise) -> response promise
(** Creates a response with a {!type-stream} open for writing, and passes the
    stream to the callback when it is ready. See example
    {{:https://github.com/aantron/dream/tree/master/example/j-stream#files}
    [j-stream]}.

    {[
      fun request ->
        Dream.stream (fun stream ->
          Dream.write stream "foo")
    ]}

    [Dream.stream] automatically closes the stream when the callback returns or
    raises an exception. Pass [~close:false] to suppress this behavior. *)

val read : stream -> string option promise
(** Retrieves a body chunk. See example
    {{:https://github.com/aantron/dream/tree/master/example/j-stream#files}
    [j-stream]}. *)
(* TODO Document difference between receiving a request and receiving on a
   WebSocket. *)

(**/**)
val with_stream : response -> response
[@@ocaml.deprecated
"Use Dream.stream instead. See
https://aantron.github.io/dream/#val-set_stream
"]
(**/**)

val write : stream -> string -> unit promise
(** Streams out the string. The promise is fulfilled when the response can
    accept more writes. *)
(* TODO Document clearly which of the writing functions can raise exceptions. *)

val flush : stream -> unit promise
(** Flushes the stream's write buffer. Data is sent to the client. *)

val close : stream -> unit promise
(** Closes the stream. *)

(** {2 Low-level streaming}

    Note: this part of the API is still a work in progress. *)

type buffer =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
(** Byte arrays in the C heap. See
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bigarray.Array1.html}
    [Bigarray.Array1]}. This type is also found in several libraries installed
    by Dream, so their functions can be used with {!Dream.buffer}:

    - {{:https://github.com/inhabitedtype/bigstringaf/blob/353cb283aef4c261597f68154eb27a138e7ef112/lib/bigstringaf.mli}
      [Bigstringaf.t]} in bigstringaf.
    - {{:https://ocsigen.org/lwt/latest/api/Lwt_bytes} [Lwt_bytes.t]} in Lwt.
    - {{:https://github.com/mirage/ocaml-cstruct/blob/9a8b9a79bdfa2a1b8455bc26689e0228cc6fac8e/lib/cstruct.mli#L139}
      [Cstruct.buffer]} in Cstruct. *)

(* TODO Probably even close can be made optional. exn can be made optional. *)
(* TODO Argument order? *)
val read_stream :
  stream ->
  data:(buffer -> int -> int -> bool -> bool -> unit) ->
  flush:(unit -> unit) ->
  ping:(buffer -> int -> int -> unit) ->
  pong:(buffer -> int -> int -> unit) ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
    unit
(** Waits for the next stream event, and calls:

    - [~data] with an offset and length, if a {!type-buffer} is received,
    ~ [~flush] if a flush request is received,
    - [~ping] if a ping is received (WebSockets only),
    - [~pong] if a pong is received (WebSockets only),
    - [~close] if the stream is closed, and
    - [~exn] to report an exception. *)

val write_stream :
  stream ->
  buffer -> int -> int ->
  bool -> bool ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
(** Writes a {!type-buffer} into the stream:

    {[
      write_stream stream buffer offset length binary fin ~close ~exn callback
    ]}

    [write_stream] calls one of its three callback functions, depending on what
    happens with the write:

    - [~close] if the stream is closed before the write completes,
    - [~exn] to report an exception during or before the write,
    - [callback] to report that the write has succeeded and the stream can
      accept another write.

    [binary] and [fin] are for WebSockets only. [binary] marks the stream as
    containing binary (non-text) data, and [fin] sets the [FIN] bit, indicating
    the end of a message. These two parameters are ignored by non-WebSocket
    streams. *)

val flush_stream :
  stream ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
(** Requests the stream be flushed. The callbacks have the same meaning as in
    {!write_stream}. *)

val ping_stream :
  stream ->
  buffer -> int -> int ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
(** Sends a ping frame on the WebSocket stream. The buffer is typically empty,
    but may contain up to 125 bytes of data. *)

val pong_stream :
  stream ->
  buffer -> int -> int ->
  close:(int -> unit) ->
  exn:(exn -> unit) ->
  (unit -> unit) ->
    unit
(** Like {!ping_stream}, but sends a pong event. *)

val close_stream : stream -> int -> unit
(** Closes the stream. The integer parameter is a WebSocket close code, and is
    ignored by non-WebSocket streams. *)

val abort_stream : stream -> exn -> unit
(** Aborts the stream, causing all readers and writers to receive the given
    exception. *)

(**/**)
val write_buffer :
  ?offset:int -> ?length:int -> response -> buffer -> unit promise
[@@ocaml.deprecated
"Use Dream.write_stream. See
https://aantron.github.io/dream/#val-write_stream
"]
(**/**)

(* TODO Ergonomics of this stream surface API. *)



(** {1 WebSockets} *)

type websocket
(** A WebSocket connection. See {{:https://tools.ietf.org/html/rfc6455} RFC
    6455} and
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API} MDN}. *)

val websocket :
  ?headers:(string * string) list ->
  ?close:bool ->
    (websocket -> unit promise) -> response promise
(** Creates a fresh [101 Switching Protocols] response. Once this response is
    returned to Dream's HTTP layer, the callback is passed a new
    {!type-websocket}, and the application can begin using it. See example
    {{:https://github.com/aantron/dream/tree/master/example/k-websocket#files}
    [k-websocket]} \[{{:http://dream.as/k-websocket} playground}\].

    {[
      let my_handler = fun request ->
        Dream.websocket (fun websocket ->
          let%lwt () = Dream.send websocket "Hello, world!");
    ]}

    [Dream.websocket] automatically closes the WebSocket when the callback
    returns or raises an exception. Pass [~close:false] to suppress this
    behavior. *)

type text_or_binary = [ `Text | `Binary ]
(** See {!send} and {!receive_fragment}. *)

type end_of_message = [ `End_of_message | `Continues ]
(** See {!send} and {!receive_fragment}. *)

val send :
  ?text_or_binary:[< text_or_binary ] ->
  ?end_of_message:[< end_of_message ] ->
    websocket -> string -> unit promise
(** Sends a single WebSocket message. The WebSocket is ready another message
    when the promise resolves.

    With [~text_or_binary:`Text], the default, the message is interpreted as a
    UTF-8 string. The client will receive it transcoded to JavaScript's UTF-16
    representation.

    With [~text_or_binary:`Binary], the message will be received unmodified, as
    either a [Blob] or an [ArrayBuffer]. See
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/binaryType}
    MDN, [WebSocket.binaryType]}.

    [~end_of_message] is ignored for now, as the WebSocket library underlying
    Dream does not support sending message fragments yet. *)

val receive : websocket -> string option promise
(** Receives a message. If the WebSocket is closed before a complete message
    arrives, the result is [None]. *)

val receive_fragment :
  websocket -> (string * text_or_binary * end_of_message) option promise
(** Receives a single fragment of a message, streaming it. *)

val close_websocket : ?code:int -> websocket -> unit promise
(** Closes the WebSocket. [~code] is usually not necessary, but is needed for
    some protocols based on WebSockets. See
    {{:https://tools.ietf.org/html/rfc6455#section-7.4} RFC 6455 §7.4}. *)



(** {1 JSON}

    Dream presently recommends using
    {{:https://github.com/ocaml-community/yojson#readme} Yojson}. See also
    {{:https://github.com/janestreet/ppx_yojson_conv#readme} ppx_yojson_conv}
    for generating JSON parsers and serializers for OCaml data types.

    See example
    {{:https://github.com/aantron/dream/tree/master/example/e-json#files}
    [e-json]}. *)

val origin_referrer_check : middleware
(** CSRF protection for AJAX requests. Either the method must be [`GET] or
    [`HEAD], or:

    - [Origin:] or [Referer:] must be present, and
    - their value must match [Host:]

    Responds with [400 Bad Request] if the check fails. See example
    {{:https://github.com/aantron/dream/tree/master/example/e-json#security}
    [e-json]}.

    Implements the
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#verifying-origin-with-standard-headers}
    OWASP {i Verifying Origin With Standard Headers}} CSRF defense-in-depth
    technique, which is good enough for basic usage. Do not allow [`GET] or
    [`HEAD] requests to trigger important side effects if relying only on
    {!Dream.origin_referrer_check}.

    Future extensions to this function may use [X-Forwarded-Host] or host
    whitelists.

    For more thorough protection, generate CSRF tokens with {!Dream.csrf_token},
    send them to the client (for instance, in [<meta>] tags of a single-page
    application), and require their presence in an [X-CSRF-Token:] header. *)



(** {1 Forms}

    {!Dream.csrf_tag} and {!Dream.val-form} round-trip secure forms.
    {!Dream.csrf_tag} is used inside a form template to generate a hidden field
    with a CSRF token:

    {[
      <form method="POST" action="/">
        <%s! Dream.csrf_tag request %>
        <input name="my.field">
      </form>
    ]}

    {!Dream.val-form} recieves the form and checks the CSRF token:

    {[
      match%lwt Dream.form request with
      | `Ok ["my.field", value] -> (* ... *)
      | _ -> Dream.empty `Bad_Request
    ]}

    See example
    {{:https://github.com/aantron/dream/tree/master/example/d-form#files}
    [d-form]} \[{{:http://dream.as/d-form} playground}\]. *)

type 'a form_result = [
  | `Ok            of 'a
  | `Expired       of 'a * float
  | `Wrong_session of 'a
  | `Invalid_token of 'a
  | `Missing_token of 'a
  | `Many_tokens   of 'a
  | `Wrong_content_type
]
(** Form CSRF checking results, in order from least to most severe. See
    {!Dream.val-form} and example
    {{:https://github.com/aantron/dream/tree/master/example/d-form#files}
    [d-form]}.

    The first three constructors, [`Ok], [`Expired], and [`Wrong_session] can
    occur in regular usage.

    The remaining constructors, [`Invalid_token], [`Missing_token],
    [`Many_tokens], [`Wrong_content_type] correspond to bugs, suspicious
    activity, or tokens so old that decryption keys have since been rotated on
    the server. *)

val form : ?csrf:bool -> request -> (string * string) list form_result promise
(** Parses the request body as a form. Performs CSRF checks. Use
    {!Dream.csrf_tag} in a form template to transparently generate forms that
    will pass these checks. See {!section-templates} and example
    {{:https://github.com/aantron/dream/tree/master/example/d-form#readme}
    [d-form]}.

    - [Content-Type:] must be [application/x-www-form-urlencoded].
    - The form must have a field named [dream.csrf]. {!Dream.csrf_tag} adds such
      a field.
    - {!Dream.form} calls {!Dream.verify_csrf_token} to check the token in
      [dream.csrf].

    The call must be done under a session middleware, since each CSRF token is
    scoped to a session. See {!section-sessions}.

    Form fields are sorted for easy pattern matching:

    {[
      match%lwt Dream.form request with
      | `Ok ["email", email; "name", name] -> (* ... *)
      | _ -> Dream.empty `Bad_Request
    ]}

    To recover from conditions like expired forms, add extra cases:

    {[
      match%lwt Dream.form request with
      | `Ok      ["email", email; "name", name] -> (* ... *)
      | `Expired (["email", email; "name", name], _) -> (* ... *)
      | _ -> Dream.empty `Bad_Request
    ]}

    It is recommended not to mutate state or send back sensitive data in the
    [`Expired] and [`Wrong_session] cases, as they {e may} indicate an attack
    against a client.

    The remaining cases, including unexpected field sets and the remaining
    constructors of {!Dream.type-form_result}, usually indicate either bugs or
    attacks. It's usually fine to respond to all of them with [400 Bad
    Request]. *)

(** {2 Upload} *)

type multipart_form =
  (string * ((string option * string) list)) list
(** Submitted file upload forms, [<form enctype="multipart/form-data">]. For
    example, if a form

    {v
<input name="files" type="file" multiple>
<input name="text">
    v}

    is submitted with two files and a text value, it will be received by
    {!Dream.multipart} as

    {[
      [
        "files", [
          Some "file1.ext", "file1-content";
          Some "file2.ext", "file2-content";
        ];
        "text", [
          None, "text-value"
        ];
      ]
    ]}

    See example
    {{:https://github.com/aantron/dream/tree/master/example/g-upload#files}
    [g-upload]} \[{{:http://dream.as/g-upload} playground}\] and
    {{:https://datatracker.ietf.org/doc/html/rfc7578} RFC 7578}.

    Note that clients such as curl can send files with no filename ([None]),
    though most browsers seem to insert at least an empty filename ([Some ""]).
    Don't use use the presence of a filename to determine if the field value is
    a file. Use the field name and knowledge about the form instead.

    If a file field has zero files when submitted, browsers send
    ["field-name", [Some ""; ""]]. {!Dream.multipart} replaces this with
    ["field-name", []]. Use the advanced interface, {!Dream.val-upload}, for the
    raw behavior.

    Non-file fields always have one value, which might be the empty string.

    See
    {{:https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html}
    OWASP {i File Upload Cheat Sheet}} for security precautions for upload
    forms. *)

val multipart : ?csrf:bool -> request -> multipart_form form_result promise
(** Like {!Dream.form}, but also reads files, and [Content-Type:] must be
    [multipart/form-data]. The CSRF token can be generated in a template with

    {[
      <form method="POST" action="/" enctype="multipart/form-data">
        <%s! Dream.csrf_tag request %>
    ]}

    See section {!section-templates}, and example
    {{:https://github.com/aantron/dream/tree/master/example/g-upload#files}
    [g-upload]}.

    Note that, like {!Dream.form}, this function sorts form fields by field
    name.

    {!Dream.multipart} reads entire files into memory, so it is only suitable
    for prototyping, or with yet-to-be-added file size and count limits. See
    {!Dream.val-upload} below for a streaming version. *)

(** {2 Streaming uploads} *)

type part = string option * string option * ((string * string) list)
(** Upload form parts.

    A value [Some (name, filename, headers)] received by {!Dream.val-upload}
    begins a {e part} in the stream. A part represents either a form field, or
    a single, complete file.

    Note that, in the general case, [filename] and [headers] are not reliable.
    [name] is the form field name. *)

val upload : request -> part option promise
(** Retrieves the next upload part.

    Upon getting [Some (name, filename, headers)] from this function, the user
    should call {!Dream.upload_part} to stream chunks of the part's data, until
    that function returns [None]. The user should then call {!Dream.val-upload}
    again. [None] from {!Dream.val-upload} indicates that all parts have been
    received.

    {!Dream.val-upload} does not verify a CSRF token. There are several ways to
    add CSRF protection for an upload stream, including:

    - Generate a CSRF token with {!Dream.csrf_tag}. Check for
      [`Field ("dream.csrf", token)] during upload and call
      {!Dream.verify_csrf_token}.
    - Use {{:https://developer.mozilla.org/en-US/docs/Web/API/FormData}
      [FormData]} in the client to submit [multipart/form-data] by AJAX, and
      include a custom header. *)

val upload_part : request -> string option promise
(** Retrieves a part chunk. *)

(** {2 CSRF tokens}

    It's usually not necessary to handle CSRF tokens directly.

    - CSRF token field generator {!Dream.csrf_tag} generates and inserts a CSRF
      token that {!Dream.val-form} and {!Dream.val-multipart} transparently
      verify.
    - AJAX can be protected from CSRF by {!Dream.origin_referrer_check}.

    CSRF functions are exposed for creating custom schemes, and for
    defense-in-depth purposes. See
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html}
    OWASP {i Cross-Site Request Forgery Prevention Cheat Sheet}}. *)

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

val csrf_token : ?valid_for:float -> request -> string
(** Returns a fresh CSRF token bound to the given request's and signed with the
    secret given to {!Dream.set_secret}. [~valid_for] is the token's lifetime,
    in seconds. The default value is one hour ([3600.]). Dream uses signed
    tokens that are not stored server-side. *)

val verify_csrf_token : request -> string -> csrf_result promise
(** Checks that the CSRF token is valid for the {!type-request}'s session. *)



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

    See examples
    {{:https://github.com/aantron/dream/tree/master/example/7-template#files}
    [7-template]} \[{{:http://dream.as/7-template} playground}\] and
    {{:https://github.com/aantron/dream/tree/master/example/r-template#files}
    [r-template]} \[{{:http://dream.as/r-template} playground}\].

    There is also a typed alternative, provided by an external library,
    {{:https://github.com/ocsigen/tyxml} TyXML}. It is shown in example
    {{:https://github.com/aantron/dream/tree/master/example/w-tyxml#files}
    [w-tyxml]} \[{{:http://dream.as/w-tyxml} playground}\]. If you are using
    Reason syntax, TyXML can be used with
    {{:https://ocsigen.org/tyxml/latest/manual/jsx} server-side JSX}. See
    example
    {{:https://github.com/aantron/dream/tree/master/example/r-tyxml#files}
    [r-tyxml]} \[{{:http://dream.as/r-tyxml} playground}\].

    To use the built-in templates, add this to [dune]:

    {v
(rule
 (targets template.ml)
 (deps template.eml.ml)
 (action (run dream_eml %{deps} --workspace %{workspace_root})))
    v}

    A template begins...

    - {e Implicitly} on a line that starts with [<], perhaps with leading
      whitespace. The line is part of the template.
    - {e Explicitly} after a line that starts with [%%]. The [%%] line is not
      part of the template.

    A [%%] line can also be used to set template options. The only option
    supported presently is [%% response] for streaming the template using
    {!Dream.write}, to a {!type-response} that is in scope. This is shown in
    examples
    {{:https://github.com/aantron/dream/tree/master/example/w-template-stream#files}
    [w-template-stream]} and
    {{:https://github.com/aantron/dream/tree/master/example/r-template-stream#files}
    [r-template-stream]}.

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
    [<script>] tags. *)

val csrf_tag : request -> string
(** Generates an [<input>] tag with a CSRF token, suitable for use with
    {!Dream.val-form} and {!Dream.val-multipart}. For example, in a template,

    {[
      <form method="POST" action="/">
        <%s! Dream.csrf_tag request %>
        <input name="my.field">
      </form>
    ]}

    expands to

    {[
      <form method="POST" action="/">
        <input name="dream.csrf" type="hidden" value="j8vjZ6...">
        <input name="my.field">
      </form>
    ]}

    It is
    {{:https://portswigger.net/web-security/csrf/tokens#how-should-csrf-tokens-be-transmitted}
    recommended} to put the CSRF tag immediately after the starting [<form>]
    tag, to prevent certain kinds of DOM manipulation-based attacks. *)

(**/**)
val form_tag :
  ?method_:[< method_ ] ->
  ?target:string ->
  ?enctype:[< `Multipart_form_data ] ->
  ?csrf_token:bool ->
    action:string -> request -> string
[@ocaml.deprecated
"Use Dream.csrf_tag. See
https://aantron.github.io/dream/#val-csrf_tag
"]
(** Generates a [<form>] tag and an [<input>] tag with a CSRF token, suitable
    for use with {!Dream.val-form} and {!Dream.val-multipart}. For example, in
    a template,

    {[
      <%s! Dream.form_tag ~action:"/" request %>
        <input name="my.field">
      </form>
    ]}

    expands to

    {[
      <form method="POST" action="/">
        <input name="dream.csrf" type="hidden" value="a-token">
        <input name="my.field">
      </form>
    ]}

    [~method] sets the method used to submit the form. The default is [`POST].

    [~target] adds a [target] attribute. For example, [~target:"_blank"] causes
    the browser to submit the form in a new tab or window.

    Pass [~enctype:`Multipart_form_data] for a file upload form.

    [~csrf_token:false] suppresses generation of the [dream.csrf] field. *)
(**/**)



(** {1 Middleware}

    Interesting built-in middlewares are scattered throughout the various
    sections of these docs, according to where they are relevant. This section
    contains only generic middleware combinators. *)

val no_middleware : middleware
(** Does nothing but call its inner handler. Useful for disabling middleware
    conditionally during application startup:

    {[
      if development then
        my_middleware
      else
        Dream.no_middleware
    ]} *)

val pipeline : middleware list -> middleware
(** Combines a sequence of middlewares into one, such that these two lines are
    equivalent:

    {v
Dream.pipeline [middleware_1; middleware_2] @@ handler
    v}
    {v
               middleware_1 @@ middleware_2 @@ handler
    v} *)

(* TODO Need a way to create fresh streams. *)
(** {2 Stream transformers}

    When writing a middleware that transforms a request body stream, use
    {!server_stream} to retrieve the server's view of the body stream. Create a
    new transformed stream (note: a function for doing this is not yet exposed),
    and replace the request's server stream by your transformed stream with
    {!set_server_stream}.

    When transforming a response stream, replace the client stream instead. *)

val client_stream : 'a message -> stream
(** The stream that clients interact with. *)

val server_stream : 'a message -> stream
(** The stream that servers interact with. *)

val set_client_stream : response -> stream -> unit
(** Replaces the stream that the client will use when it receives the
    response. *)

val set_server_stream : request -> stream -> unit
(** Replaces the stream that the server will use when it receives the
    request. *)



(** {1 Routing} *)

val router : route list -> handler
(** Creates a router. If none of the routes match the request, the router
    returns {!Dream.not_found}. Route components starting with [:] are
    parameters, which can be retrieved with {!Dream.param}. See example
    {{:https://github.com/aantron/dream/tree/master/example/3-router#files}
    [3-router]} \[{{:http://dream.as/3-router} playground}\].

    {[
      let () =
        Dream.run
        @@ Dream.router [
          Dream.get "/echo/:word" @@ fun request ->
            Dream.html (Dream.param "word" request);
        ]
    ]}

    {!Dream.scope} is the main form of site composition. However, Dream also
    supports full subsites with [**]:

    {[
      let () =
        Dream.run
        @@ Dream.router [
          Dream.get "/static/**" @@ Dream.static "www/static";
        ]
    ]}

    [**] causes the request's path to be trimmed by the route prefix, and the
    request's prefix to be extended by it. It is mainly useful for “mounting”
    {!Dream.static} as a subsite.

    It can also be used as an escape hatch to convert a handler, which may
    include its own router, into a subsite. However, it is better to compose
    sites with routes and {!Dream.scope} rather than opaque handlers and [**],
    because, in the future, it may be possible to query routes for site
    structure metadata. *)

val get     : string -> handler -> route
(** Forwards [`GET] requests for the given path to the handler.

    {[
      Dream.get "/home" home_template
    ]} *)

val post    : string -> handler -> route
val put     : string -> handler -> route
val delete  : string -> handler -> route
val head    : string -> handler -> route
val connect : string -> handler -> route
val options : string -> handler -> route
val trace   : string -> handler -> route
val patch   : string -> handler -> route
(** Like {!Dream.get}, but for each of the other {{!type-method_} methods}. *)

val any     : string -> handler -> route
(** Like {!Dream.get}, but does not check the method. *)

val not_found : handler
(** Always responds with [404 Not Found]. *)

(* :((( *)
val param : request -> string -> string
(** Retrieves the path parameter. If it is missing, {!Dream.param} raises an
    exception — the program is buggy. *)

val scope : string -> middleware list -> route list -> route
(** Groups routes under a common path prefix and middlewares. Middlewares are
    run only if a route matches.

    {[
      Dream.scope "/api" [Dream.origin_referrer_check] [
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
      Dream.scope "/" [Dream.origin_referrer_check] [
        (* ...routes... *)
      ]
    ]}

    Scopes can be nested. *)

val no_route : route
(** A dummy value of type {!type-route} that is completely ignored by the
    router. Useful for disabling routes conditionally during application start:

    {[
      Dream.router [
        if development then
          Dream.get "/graphiql" (Dream.graphiql "/graphql")
        else
          Dream.no_route;
      ]
    ]} *)



(** {1 Static files} *)

val static :
  ?loader:(string -> string -> handler) ->
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
    ]}

    [Dream.static local_directory] validates the path substituted for [**] by
    checking that it is (1) relative, (2) does not contain parent directory
    references ([..]), and (3) does not contain separators ([/]) within
    components. If these checks fail, {!Dream.static} responds with [404 Not
    Found].

    If the checks succeed, {!Dream.static} calls [~loader local_directory path
    request], where

    - [local_directory] is the same directory that was passed to
      {!Dream.static}.
    - [path] is what was substituted for [**].

    The default loader is {!Dream.from_filesystem}. See example
    {{:https://github.com/aantron/dream/tree/master/example/w-one-binary#files}
    [w-one-binary]} for a loader that serves files from memory instead. *)

val from_filesystem : string -> string -> handler
(** [Dream.from_filesystem local_directory path request] responds with a file
    from the file system found at [local_directory ^ "/" ^ path].
    If such a file does not exist, it responds with [404 Not Found].

    To serve single files like [sitemap.xml] from the file system, use routes
    like

    {[
      Dream.get "/sitemap.xml" (Dream.from_filesystem "assets" "sitemap.xml")
    ]}

    {!Dream.from_filesystem} calls {!Dream.mime_lookup} to guess a
    [Content-Type:] based on the file's extension. *)

val mime_lookup : string -> (string * string) list
(** Returns a [Content-Type:] header based on the given filename. This is mostly
    a wrapper around {{:https://github.com/mirage/ocaml-magic-mime} magic-mime}.
    However, if the result is [text/html], {!Dream.mime_lookup} replaces it with
    [text/html; charset=utf-8], so as to match {!Dream.html}. *)



(** {1 Sessions}

    Dream's default sessions contain string-to-string dictionaries for
    application data. For example, a logged-in session might have

    {[
      [
        "user", "someone";
        "lang", "ut-OP";
      ]
    ]}

    Sessions also have three pieces of metadata:

    - {!Dream.session_id}
    - {!Dream.session_label}
    - {!Dream.session_expires_at}

    There are several back ends, which decide where the sessions are stored:

    - {!Dream.memory_sessions}
    - {!Dream.sql_sessions}
    - {!Dream.cookie_sessions}

    All requests passing through session middleware are assigned a session,
    either an existing one, or a new empty session, known as a {e pre-session}.

    When a session is at least half-expired, it is automatically refreshed by
    the next request that it is assigned to.

    See example
    {{:https://github.com/aantron/dream/tree/master/example/b-session#files}
    [b-session]} \[{{:http://dream.as/b-session} playground}\]. *)

val session_field : request -> string -> string option
(** Value from the request's session. *)

(**/**)
val session : string -> request -> string option
[@ocaml.deprecated
"Renamed to Dream.session_field. See
https://aantron.github.io/dream/#val-session_field
"]
(**/**)

val set_session_field : request -> string -> string -> unit promise
(** Mutates a value in the request's session. The back end may commit the value
    to storage immediately, so this function returns a promise. *)

(**/**)
val put_session : string -> string -> request -> unit promise
[@ocaml.deprecated
"Renamed to Dream.set_session_field. See
https://aantron.github.io/dream/#val-set_session_field
"]
(**/**)

val all_session_fields : request -> (string * string) list
(** Full session dictionary. *)

(**/**)
val all_session_values : request -> (string * string) list
[@ocaml.deprecated
"Renamed to Dream.all_session_fields. See
https://aantron.github.io/dream/#val-all_session_fields
"]
(**/**)

val invalidate_session : request -> unit promise
(** Invalidates the request's session, replacing it with a fresh, empty
    pre-session. *)

(** {2 Back ends} *)

val memory_sessions : ?lifetime:float -> middleware
(** Stores sessions in server memory. Passes session IDs to clients in cookies.
    Session data is lost when the server process exits. *)

val cookie_sessions : ?lifetime:float -> middleware
(** Stores sessions in encrypted cookies. Use {!Dream.set_secret} to be able to
    decrypt cookies from previous server runs. *)

val sql_sessions : ?lifetime:float -> middleware
(** Stores sessions in an SQL database. Passes session IDs to clients in
    cookies. Must be used under {!Dream.sql_pool}. Expects a table

    {v
CREATE TABLE dream_session (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  expires_at REAL NOT NULL,
  payload TEXT NOT NULL
)
    v} *)

(** {2 Metadata} *)

val session_id : request -> string
(** Secret value used to identify a client. *)

val session_label : request -> string
(** Tracing label suitable for printing to logs. *)

val session_expires_at : request -> float
(** Time at which the session will expire. *)



(** {1 Flash messages}

    Flash messages are short strings which are stored in cookies during one
    request, to be made available for the next request. The typical use case is
    to provide form feedback across a redirect. See example
    {{:https://github.com/aantron/dream/tree/master/example/w-flash#files}
    [w-flash]} \[{{:http://dream.as/w-flash} playground}\]. *)

val flash : middleware
(** Implements storing flash messages in cookies. *)

val flash_messages : request -> (string * string) list
(** The request's flash messages. *)

val add_flash_message : request -> string -> string -> unit
(** Adds a flash message to the request. *)

(**/**)
val put_flash : request -> string -> string -> unit
[@@ocaml.deprecated
"Renamed to Dream.add_flash_message. See
https://aantron.github.io/dream/#val-add_flash_message
"]
(**/**)



(** {1 GraphQL}

    Dream integrates {{:https://github.com/andreas/ocaml-graphql-server#readme}
    ocaml-graphql-server}. See examples:

    - {{:https://github.com/aantron/dream/tree/master/example/i-graphql#files}
      [i-graphql]} \[{{:http://dream.as/i-graphql} playground}\]
    - {{:https://github.com/aantron/dream/tree/master/example/r-graphql#files}
      [r-graphql]} \[{{:http://dream.as/r-graphql} playground}\]
    - {{:https://github.com/aantron/dream/tree/master/example/w-graphql-subscription#files}
      [w-graphql-subscription]} \[{{:http://dream.as/w-graphql-subscription}
      playground}\].

    If you are also
    {{:https://github.com/aantron/dream/tree/master/example#full-stack} writing
    a client in a flavor of OCaml}, consider
    {{:https://github.com/reasonml-community/graphql-ppx} graphql-ppx} for
    generating GraphQL queries.

    See
    {{:https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html}
    OWASP {i GraphQL Cheat Sheet}} for an overview of security topics related to
    GraphQL. *)

val graphql : (request -> 'a promise) -> 'a Graphql_lwt.Schema.schema -> handler
(** [Dream.graphql make_context schema] serves the GraphQL [schema].

    {[
      let () =
        Dream.run
        @@ Dream.router [
          Dream.any "/graphql"  (Dream.graphql Lwt.return schema);
          Dream.get "/graphiql" (Dream.graphiql "/graphql");
        ]
    ]}

    [make_context] is called by {!Dream.val-graphql} on every {!type-request} to
    create the {e context}, a value that is passed to each resolver from the
    schema. Passing [Lwt.return], the same as

    {[
      fun request -> Lwt.return request
    ]}

    causes the {!type-request} itself to be used as the context:

    {[
      field "name"
        ~doc:"User name"
        ~typ:(non_null string)
        ~args:Arg.[]
        ~resolve:(fun info user ->
          (* The context is in info.ctx *)
          user.name);
    ]} *)

val graphiql : ?default_query:string -> string -> handler
(** Serves
    {{:https://github.com/graphql/graphiql/tree/main/packages/graphiql#readme}
    GraphiQL}, a GraphQL query editor. The string gives the GraphQL endpoint
    that the editor will work with.

    [~default_query] sets the query that appears upon the first visit to the
    endpoint. It is empty by default. The string is pasted literally into the
    content of a JavaScript string, between its quotes, so it must be escaped
    manually.

    Dream's build of GraphiQL is found in the
    {{:https://github.com/aantron/dream/tree/master/src/graphiql} src/graphiql}
    directory. If you have the need, you can use it as the starting point for
    your own customized GraphiQL.

    Use {!Dream.no_route} to disable GraphiQL conditionally outside of
    development. *)



(** {1 SQL}

    Dream provides thin convenience functions over
    {{:https://github.com/paurkedal/ocaml-caqti/#readme} Caqti}, an SQL
    interface with several back ends. See example
    {{:https://github.com/aantron/dream/tree/master/example/h-sql#files}
    [h-sql]} \[{{:http://dream.as/h-sql} playground}\].

    Dream installs the core {{:https://opam.ocaml.org/packages/caqti/} [caqti]}
    package, but you should also install at least one of:

    - {{:https://opam.ocaml.org/packages/caqti-driver-sqlite3/}
      [caqti-driver-sqlite3]}
    - {{:https://opam.ocaml.org/packages/caqti-driver-postgresql/}
      [caqti-driver-postgresql]}
    - {{:https://opam.ocaml.org/packages/caqti-driver-mariadb/}
      [caqti-driver-mariadb]}

    They are separated because each has its own system library dependencies.
    Regardless of which you install, usage on the OCaml level is the same. The
    differences are in SQL syntax, and in external SQL server or file setup. See

    - {{:https://sqlite.org/lang.html} SQLite3, {i SQL As Understood By SQLite}}
    - {{:https://www.postgresql.org/docs/13/sql.html} PostgreSQL, {i The SQL
      Language}}
    - {{:https://mariadb.com/kb/en/sql-statements-structure/} MariaDB, {i SQL
      Statements & Structure}}

    For an introductory overview of database security, see
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html}
    OWASP {i Database Security Cheat Sheet}}. *)

val sql_pool : ?size:int -> string -> middleware
(** Makes an SQL connection pool available to its inner handler. *)

val sql : request -> (Caqti_lwt.connection -> 'a promise) -> 'a promise
(** Runs the callback with a connection from the SQL pool. See example
    {{:https://github.com/aantron/dream/tree/master/example/h-sql#files}
    [h-sql]}.

    {[
      let () =
        Dream.run
        @@ Dream.sql_pool "sqlite3:db.sqlite"
        @@ fun request ->
          Dream.sql request (fun db ->
            (* ... *) |> Dream.html)
    ]} *)



(** {1 Logging}

    Dream uses the {{:https://erratique.ch/software/logs/doc/Logs/index.html}
    Logs} library internally, and integrates with all other libraries in your
    project that are also using it. Dream provides a slightly simplified
    interface to Logs.

    All log output is written to [stderr].

    See
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html}
    OWASP {i Logging Cheat Sheet}} for a survey of security topics related to
    logging. *)

val logger : middleware
(** Logs and times requests. Time spent logging is included. See example
    {{:https://github.com/aantron/dream/tree/master/example/2-middleware#files}
    [2-middleware]} \[{{:http://dream.as/2-middleware} playground}\]. *)

val log : ('a, Format.formatter, unit, unit) format4 -> 'a
(** Formats a message and logs it. Disregard the obfuscated type: the first
    argument is a format string as described in the standard library modules
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html#VALfprintf}
    [Printf]} and
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Format.html#VALfprintf}
    [Format]}. The rest of the arguments are determined by the format string.
    See example
    {{:https://github.com/aantron/dream/tree/master/example/a-log#files}
    [a-log]} \[{{:http://dream.as/a-log} playground}\].

    {[
      Dream.log "Counter is now: %i" counter;
      Dream.log "Client: %s" (Dream.client request);
    ]} *)

type ('a, 'b) conditional_log =
  ((?request:request ->
   ('a, Format.formatter, unit, 'b) format4 -> 'a) -> 'b) ->
    unit
(** Loggers. This type is difficult to read — instead, see {!Dream.val-error} for
    usage. *)

type log_level = [
  | `Error
  | `Warning
  | `Info
  | `Debug
]
(** Log levels, in order from most urgent to least. *)

val error     : ('a, unit) conditional_log
(** Formats a message and writes it to the log at level [`Error]. The inner
    formatting function is called only if the {{!initialize_log} current log
    level} is [`Error] or higher. See example
    {{:https://github.com/aantron/dream/tree/master/example/a-log#files}
    [a-log]}.

    {[
      Dream.error (fun log ->
        log ~request "My message, details: %s" details);
    ]}

    Pass the optional argument [~request] to {!Dream.val-error} to associate the
    message with a specific request. If not passed, {!Dream.val-error} will try
    to guess the request. This usually works, but not always. *)

val warning   : ('a, unit) conditional_log
val info      : ('a, unit) conditional_log
val debug     : ('a, unit) conditional_log
(** Like {!Dream.val-error}, but for each of the other {{!log_level} log
    levels}. *)

type sub_log = {
  error   : 'a. ('a, unit) conditional_log;
  warning : 'a. ('a, unit) conditional_log;
  info    : 'a. ('a, unit) conditional_log;
  debug   : 'a. ('a, unit) conditional_log;
}
(** Sub-logs. See {!Dream.val-sub_log} right below. *)

val sub_log : ?level:[< log_level] -> string -> sub_log
(** Creates a new sub-log with the given name. For example,

    {[
      let log = Dream.sub_log "myapp.ajax"
    ]}

    ...creates a logger that can be used like {!Dream.val-error} and the other
    default loggers, but prefixes ["myapp.ajax"] to each log message.

    {[
      log.error (fun log -> log ~request "Validation failed")
    ]}

    [?level] sets the log level threshold for this sub-log only. If not
    provided, falls back to the global log level set by {!Dream.initialize_log},
    unless {!Dream.set_log_level} is used.

    See [README] of example
    {{:https://github.com/aantron/dream/tree/master/example/a-log#files}
    [a-log]}. *)

val initialize_log :
  ?backtraces:bool ->
  ?async_exception_hook:bool ->
  ?level:[< log_level ] ->
  ?enable:bool ->
    unit -> unit
(** Initializes Dream's log with the given settings.

    Dream initializes its logging back end lazily. This is so that if a Dream
    Web app is linked into a larger binary, it does not affect that binary's
    runtime unless the Web app runs.

    This also allows the Web app to give logging settings explicitly by calling
    {!Dream.initialize_log} early in program execution.

    - [~backtraces:true], the default, causes Dream to call
      {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printexc.html#VALrecord_backtrace}
      [Printexc.record_backtrace]}, which makes exception backtraces available.

    - [~async_exception_hook:true], the default, causes Dream to set
      {{:https://ocsigen.org/lwt/latest/api/Lwt#VALasync_exception_hook}
      [Lwt.async_exception_hook]} so as to forward all asynchronous exceptions
      to the logger, and not terminate the process.

    - [~level] sets the log level threshold for the entire binary. The default
      is [`Info].

    - [~enable:false] disables Dream logging completely. This can help sanitize
      output during testing. *)

val set_log_level : string -> [< log_level ] -> unit
(** Set the log level threshold of the given sub-log. *)



(** {1 Errors}

    Dream passes all errors to a single error handler, including...

    - exceptions and rejected promises from the application,
    - [4xx] and [5xx] responses from the application, and
    - lower-level errors, such as TLS handshake failures and malformed HTTP
      requests.

    This allows customizing error handling in one place. Including low-level
    errors prevents leakage of strings in automatic responses not under the
    application's control, for full internationalization.

    Use {!Dream.error_template} and pass the result to {!Dream.run}
    [~error_handler] to customize the error template.

    The default error handler logs errors and its template generates
    completely empty responses, to avoid internationalization issues. In
    addition, this conforms to the recommendations in
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html}
    OWASP {i Error Handling Cheat Sheet}}.

    For full control over error handling, including logging, you can define an
    {!type-error_handler} directly. *)

type error = {
  condition : [
    | `Response of response
    | `String of string
    | `Exn of exn
  ];
  layer : [
    | `App
    | `HTTP
    | `HTTP2
    | `TLS
    | `WebSocket
  ];
  caused_by : [
    | `Server
    | `Client
  ];
  request : request option;
  response : response option;
  client : string option;
  severity : log_level;
  will_send_response : bool;
}
(** Detailed errors. Ignore this type if only using {!Dream.error_template}.

    {ul
    {li
    [condition] describes the error itself.

    - [`Response] is a [4xx] or [5xx] response.
    - [`String] is an error that has only an English-language description.
    - [`Exn] is a caught exception.

    The default error handler logs [`Exn] and [`Strings], but not [`Response].
    [`Response] is assumed to be deliberate, and already logged by
    {!Dream.logger}.
    }

    {li
    [layer] is which part of the Dream stack detected the error.

    - [`App] is for application exceptions, rejections, and [4xx], [5xx]
      responses.
    - [`HTTP] and [`HTTP2] are for low-level HTTP protocol errors.
    - [`TLS] is for low-level TLS errors.
    - [`WebSocket] is for WebSocket errors.

    The default error handler uses this to just prepend a prefix to its log
    messages.
    }

    {li
    [caused_by] is the party likely to have caused the error.

    - [`Server] errors suggest bugs, and correspond to [5xx] responses.
    - [`Client] errors suggest user errors, network failure, buggy clients, and
      sometimes attacks. They correspond to [4xx] responses.
    }

    {li
    [request] is a {!type-request} associated with the error, if there is one.

    As examples, a request might not be available if the error is a failure to
    parse an HTTP/1.1 request at all, or failure to perform a TLS handshake.

    In case of a [`WebSocket] error, the request is the client's original
    request to establish the WebSocket connection.
    }

    {li
    [response] is a {!type-response} that was either generated by the
    application, or suggested by the error context.

    In case of a [`WebSocket] error, the response is the application's original
    connection agreement response created by {!Dream.val-websocket}.

    See {!Dream.error_template}.
    }

    {li
    [client] is the client's address, if available. For example,
    [127.0.0.1:56001].
    }

    {li
    Suggested {{!type-log_level} log level} for the error. Usually [`Error] for
    [`Server] errors and [`Warning] for client errors.
    }

    {li
    [will_send_response] is [true] in error contexts where Dream will still send
    a response.

    The default handler calls the error template only if [will_send_response] is
    [true].
    }} *)

type error_handler = error -> response option promise
(** Error handlers log errors and convert them into responses. Ignore if using
    {!Dream.error_template}.

    If the error has [will_send_response = true], the error handler must return
    a response. Otherwise, it should return [None].

    If an error handler raises an exception or rejects, Dream logs this
    secondary failure. If the error context needs a response, Dream responds
    with an empty [500 Internal Server Error].

    The behavior of Dream's default error handler is described at
    {!Dream.type-error}. *)
(* TODO Get rid of the option? *)

val error_template :
  (error -> string -> response -> response promise) -> error_handler
(** Builds an {!error_handler} from a template. See example
    {{:https://github.com/aantron/dream/tree/master/example/9-error#files}
    [9-error]} \[{{:http://dream.as/9-error} playground}\].

    {[
      let my_error_handler =
        Dream.error_template (fun _error debug_dump suggested_response ->
          let body =
            match debug_dump with
            | Some string -> Dream.html_escape string
            | None -> Dream.status_to_string (Dream.status suggested_response)
          in

          suggested_response
          |> Dream.with_body body
          |> Lwt.return)
    ]}

    The error's context suggests a response. Usually, its only valid field is
    {!Dream.val-status}.

    - If the error is an exception or rejection from the application, the status
      is usually [500 Internal Server Error].
    - In case of a [4xx] or [5xx] response from the application, that response
      itself is passed to the template.
    - For low-level errors, the status is typically either [400 Bad Request] if
      the error was likely caused by the client, and [500 Internal Server Error]
      if the error was likely caused by the server.

    [~debug_dump] is a multi-line string containing an error description, stack
    trace, request state, and other information.

    When an error occurs in a context where a response is not possible, the
    template is not called. In some contexts where the template is called, the
    status code is hardcoded, but the headers and body from the template's
    response will still be used.

    If the template itself raises an exception or rejects, an empty [500
    Internal Server Error] will be sent in contexts that require a response. *)

val debug_error_handler : error_handler
(** An {!error_handler} for showing extra information about requests and
    exceptions, for use during development. *)

val catch : (error -> response promise) -> middleware
(** Forwards exceptions, rejections, and [4xx], [5xx] responses from the
    application to the error handler. See {!section-errors}. *)
(* TODO Error handler should not return an option, and then the type can be
   used here. *)



(** {1 Servers} *)

val run :
  ?interface:string ->
  ?port:int ->
  ?stop:unit promise ->
  ?error_handler:error_handler ->
  ?tls:bool ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?builtins:bool ->
  ?greeting:bool ->
  ?adjust_terminal:bool ->
    handler -> unit
(** Runs the Web application represented by the {!handler}, by default at
    {{:http://localhost:8080} http://localhost:8080}.

    This function calls {{:https://ocsigen.org/lwt/latest/api/Lwt_main#VALrun}
    [Lwt_main.run]} internally, so it is intended to be the main loop of a
    program. {!Dream.serve} is a version that does not call [Lwt_main.run].

    - [~interface] is the network interface to listen on. Defaults to
      ["localhost"]. Use ["0.0.0.0"] to listen on all interfaces.
    - [~port] is the port to listen on. Defaults to [8080].
    - [~stop] is a promise that causes the server to stop accepting new
      requests, and {!Dream.run} to return. Requests that have already entered
      the Web application continue to be processed. The default value is a
      promise that never resolves. However, see also [~stop_on_input].
    - [~debug:true] enables debug information in error templates. See
      {!Dream.error_template}. The default is [false], to prevent accidental
      deployment with debug output turned on. See example
      {{:https://github.com/aantron/dream/tree/master/example/8-debug#files}
      [8-debug]} \[{{:http://dream.as/8-debug} playground}\].
    - [~error_handler] handles all errors, both from the application, and
      low-level errors. See {!section-errors} and example
      {{:https://github.com/aantron/dream/tree/master/example/9-error#files}
      [9-error]} \[{{:http://dream.as/9-error} playground}\].
    - [~tls:true] enables TLS. You should also specify [~certificate_file] and
      [~key_file]. However, for development, Dream includes an insecure
      compiled-in
      {{:https://github.com/aantron/dream/tree/master/src/certificate#files}
      localhost certificate}. Enabling HTTPS also enables transparent upgrading
      of connections to HTTP/2. See example
      {{:https://github.com/aantron/dream/tree/master/example/l-https#files}
      [l-https]}.
    - [~certificate_file] and [~key_file] specify the certificate and key file,
      respectively, when using [~tls]. They are not required for development,
      but are required for production. Dream will write a warning to the log if
      you are using [~tls], don't provide [~certificate_file] and [~key_file],
      and [~interface] is not ["localhost"].
    - [~builtins:false] disables {!section-builtin}.

    The remaining arguments can be used to gradually disable convenience
    features of [Dream.run]. Once both are disabled, you may want to switch to
    using {!Dream.serve}.

    - [~greeting:false] disables the start-up log message that prints a link to
      the Web application.
    - [~adjust_terminal:false] disables adjusting the terminal to disable echo
      and line wrapping. *)

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit promise ->
  ?error_handler:error_handler ->
  ?tls:bool ->
  ?certificate_file:string ->
  ?key_file:string ->
  ?builtins:bool ->
    handler -> unit promise
(** Like {!Dream.run}, but returns a promise that does not resolve until the
    server stops listening, instead of calling
    {{:https://ocsigen.org/lwt/latest/api/Lwt_main#VALrun} [Lwt_main.run]}.

    This function is meant for integrating Dream applications into larger
    programs that have their own procedures for starting and stopping the Web
    server.

    All arguments have the same meanings as they have in {!Dream.run}. *)

(** {2:builtin Built-in middleware}

    Built-in middleware is Dream functionality that is implemented as middleware
    for maintainability reasons. It is necessary for Dream to work correctly.
    However, because it is middleware, Dream allows replacing it with
    {!Dream.run} [~builtins:false]. The middleware is applied in documented
    order, so

    {[
      Dream.run my_app
    ]}

    is the same as

    {[
      Dream.run ~builtins:false
      @@ Dream.catch ~error_handler
      @@ my_app
    ]}

    The middleware can be replaced with work-alikes, or omitted to use Dream as
    a fairly raw abstraction layer over low-level HTTP libraries. *)

val with_site_prefix : string -> middleware
(** Removes the given prefix from the path in each request, and adds it to the
    request prefix. Responds with [502 Bad Gateway] if the path does not have
    the expected prefix.

    This is for applications that are not running at the root ([/]) of their
    domain. The default is ["/"], for no prefix. After [with_site_prefix],
    routing is done relative to the prefix, and the prefix is also necessary for
    emitting secure cookies. *)
(* TODO Clarify that this isn't included with the built-ins, but is something on
   topic that one might want to use. *)



(** {1:web_formats Web formats} *)

val html_escape : string -> string
(** Escapes a string so that it is suitable for use as text inside HTML
    elements and quoted attribute values. Implements
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-1-html-encode-before-inserting-untrusted-data-into-html-element-content}
    OWASP {i Cross-Site Scripting Prevention Cheat Sheet RULE #1}}.

    This function is {e not} suitable for use with unquoted attributes, inline
    scripts, or inline CSS. See {i Security} in example
    {{:https://github.com/aantron/dream/tree/master/example/7-template#security}
    [7-template]}. *)

val to_base64url : string -> string
(** Converts the given string its base64url encoding, as specified in
    {{:https://tools.ietf.org/html/rfc4648#section-5} RFC 4648 §5}, using a
    Web-safe alphabet and no padding. The resulting string can be used without
    escaping in URLs, form data, cookies, HTML content, attributes, and
    JavaScript code. For more options, see the
    {{:https://mirage.github.io/ocaml-base64/base64/Base64/index.html} Base64}
    library.*)

val from_base64url : string -> string option
(** Inverse of {!Dream.to_base64url}. *)

val to_percent_encoded : ?international:bool -> string -> string
(** Percent-encodes a string for use inside a URL.

    [~international] is [true] by default, and causes non-ASCII bytes to be
    preserved. This is suitable for display to users, including in [<a href="">]
    attributes, which are displayed in browser status lines. See
    {{:https://tools.ietf.org/html/rfc3987} RFC 3987}.

    Use [~international:false] for compatibility with legacy systems, or when
    constructing URL fragments from untrusted input that may not match the
    interface language(s) the user expects. In the latter case, similar letters
    from different writing scripts can be used to mislead users about the
    targets of links. *)

val from_percent_encoded : string -> string
(** Inverse of {!Dream.to_percent_encoded}. *)

val to_form_urlencoded : (string * string) list -> string
(** Inverse of {!Dream.from_form_urlencoded}. Percent-encodes names and
    values. *)

val from_form_urlencoded : string -> (string * string) list
(** Converts form data or a query string from
    [application/x-www-form-urlencoded] format to a list of name-value pairs.
    See {{:https://tools.ietf.org/html/rfc1866#section-8.2.1} RFC 1866
    §8.2.1}. Reverses the percent-encoding of names and values. *)

val from_cookie : string -> (string * string) list
(** Converts a [Cookie:] header value to key-value pairs. See
    {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-4.2.1}
    RFC 6265bis §4.2.1}. Does not apply any decoding to names and values. *)

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
    {{:https://tools.ietf.org/html/draft-ietf-httpbis-rfc6265bis-07#section-5.3}
    RFC 6265bis §5.3}, and are documented at {!Dream.set_cookie}.

    Does not apply any encoding to names and values. Be sure to encode so that
    names and values cannot contain `=`, `;`, or newline characters. *)

val split_target : string -> string * string
(** Splits a request target into a path and a query string. *)

val from_path : string -> string list
(** Splits the string into components on [/] and percent-decodes each component.
    Empty components are dropped, except for the last. This function does not
    distinguish between absolute and relative paths, and is only meant for
    routes and request targets. So,

    - [Dream.from_path ""] becomes [[]].
    - [Dream.from_path "/"] becomes [[""]].
    - [Dream.from_path "abc"] becomes [["abc"]].
    - [Dream.from_path "/abc"] becomes [["abc"]].
    - [Dream.from_path "abc/"] becomes [["abc"; ""]].
    - [Dream.from_path "a%2Fb"] becomes [["a/b"]].
    - [Dream.from_path "a//b"] becomes [["a"; "b"]].

    This function is not for use on full targets, because they may incldue query
    strings ([?]), and {!Dream.from_path} does not treat them specially. Split
    query strings off with {!Dream.split_target} first. *)

val to_path : ?relative:bool -> ?international:bool -> string list -> string
(** Percent-encodes a list of path components and joins them with [/] into a
    path. Empty components, except for the last, are removed. The path is
    absolute by default. Use [~relative:true] for a relative path.
    {!Dream.to_path} uses an IRI-friendly percent encoder, which preserves UTF-8
    bytes in unencoded form. Use [~international:false] to percent-encode those
    bytes as well, for legacy protocols that require ASCII URLs. *)

val drop_trailing_slash : string list -> string list
(** Changes the representation of path [abc/] to the representation of [abc] by
    checking if the last element in the list is [""], and, if it is, dropping
    it. *)

val text_html : string
(** The string ["text/html; charset=utf-8"] for [Content-Type:] headers. *)

val application_json : string
(** The string ["application/json"] for [Content-Type:] headers. *)



(** {1 Cryptography} *)

val set_secret : ?old_secrets:string list -> string -> middleware
(** Sets a key to be used for cryptographic operations, such as signing CSRF
    tokens and encrypting cookies.

    If this middleware is not used, a random secret is generated the first time
    a secret is needed. The random secret persists for the lifetime of the
    process. This is useful for quick testing and prototyping, but it means that
    restarts of the server will not be able to verify tokens or decrypt cookies
    generated by earlier runs, and multiple servers in a load-balancing
    arrangement will not accept each others' tokens and cookies.

    For production, generate a 256-bit key with

    {[
      Dream.to_base64url (Dream.random 32)
    ]}

    [~old_secrets] is a list of previous secrets that will not be used for
    encryption or signing, but will still be tried for decryption and
    verification. This is intended for key rotation. A medium-sized Web app
    serving 1000 fresh encrypted cookies per second should rotate keys about
    once a year. *)

val random : int -> string
(** Generates the requested number of bytes using a
    {{:https://github.com/mirage/mirage-crypto} cryptographically secure random
    number generator}. *)

val encrypt :
  ?associated_data:string ->
    request -> string -> string
(** Signs and encrypts the string using the secret set by {!Dream.set_secret}.

    [~associated_data] is included when computing the signature, but not
    included in the ciphertext. It can be used like a “salt,” to force
    ciphertexts from different contexts to be distinct, and dependent on the
    context.

    For example, when {!Dream.set_cookie} encrypts cookie values, it internally
    passes the cookie names in the associated data. This makes it impossible (or
    impractical) to use the ciphertext from one cookie as the value of another.
    The associated data will not match, and the value will be recognized as
    invalid.

    The cipher presently used by Dream is
    {{:https://tools.ietf.org/html/rfc5116#section-5.2} AEAD_AES_256_GCM}. It
    will be replaced by
    {{:https://tools.ietf.org/html/rfc8452} AEAD_AES_256_GCM_SIV} as soon as the
    latter is {{:https://github.com/mirage/mirage-crypto/issues/111} available}.
    The upgrade will be transparent, because Dream includes a cipher rotation
    scheme.

    The cipher is suitable for encrypted transmissions and storing data other
    than credentials. For password or other credential storage, see package
    {{:https://github.com/Khady/ocaml-argon2} [argon2]}. See
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html}
    OWASP {i Cryptographic Storage Cheat Sheet}} and
    {{:https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html}
    OWASP {i Password Storage Cheat Sheet}}. *)

val decrypt :
  ?associated_data:string ->
    request -> string -> string option
(** Reverses {!Dream.encrypt}.

    To support secret rotation, this function first tries to decrypt the string
    using the main secret set by {!Dream.set_secret}, and then each of the old
    secrets passed to {!Dream.set_secret} in [~old_secrets]. *)



(** {1 Variables}

    Dream supports user-defined per-message variables for use by middlewares. *)

type 'a field
(** Per-message variable. *)

(**/**)
type 'a local = 'a field
[@@ocaml.deprecated
"Renamed to type Dream.field. See
https://aantron.github.io/dream/#type-field
"]
(**/**)

val new_field : ?name:string -> ?show_value:('a -> string) -> unit -> 'a field
(** Declares a variable of type ['a] in all messages. The variable is initially
    unset in each message. The optional [~name] and [~show_value] are used by
    {!Dream.run} [~debug] to show the variable in debug dumps. *)

(**/**)
val new_local : ?name:string -> ?show_value:('a -> string) -> unit -> 'a field
[@@ocaml.deprecated
"Renamed to Dream.new_field. See
https://aantron.github.io/dream/#val-new_field
"]
(**/**)

val field : 'b message -> 'a field -> 'a option
(** Retrieves the value of the per-message variable. *)

(**/**)
val local : 'b message -> 'a field -> 'a option
[@@ocaml.deprecated
"Renamed to Dream.field. See
https://aantron.github.io/dream/#val-field
"]
(**/**)

val set_field : 'b message -> 'a field -> 'a -> unit
(** Sets the per-message variable to the value. *)

(**/**)
val with_local : 'a field -> 'a -> 'b message -> 'b message
[@@ocaml.deprecated
"Use Dream.set_field instead. See
https://aantron.github.io/dream/#val-set_field
"]
(**/**)



(** {1 Testing} *)

val request :
  ?method_:[< method_ ] ->
  ?target:string ->
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

(**/**)
val first : 'a message -> 'a message
[@@ocaml.deprecated "Simply returns its own argument."]
(** [Dream.first message] evaluates to the original request or response that
    [message] is immutably derived from. This is useful for getting the original
    state of requests especially, when they were first created inside the HTTP
    server ({!Dream.run}). *)

val last : 'a message -> 'a message
[@@ocaml.deprecated "Simply returns its own argument."]
(** [Dream.last message] evaluates to the latest request or response that was
    derived from [message]. This is most useful for obtaining the state of
    requests at the time an exception was raised, without having to instrument
    the latest version of the request before the exception. *)
(**/**)

val sort_headers : (string * string) list -> (string * string) list
(** Sorts headers by name. Headers with the same name are not sorted by value or
    otherwise reordered, because order is significant for some headers. See
    {{:https://tools.ietf.org/html/rfc7230#section-3.2.2} RFC 7230 §3.2.2} on
    header order. This function can help sanitize output before comparison. *)

val echo : handler
(** Responds with the request body. *)
