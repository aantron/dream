type method_ = [
  | `GET
  | `POST
  | `PUT
  | `DELETE
  | `HEAD
  | `CONNECT
  | `OPTIONS
  | `TRACE
  | `Other of string
]

let method_to_string = function
  | `GET -> "GET"
  | `POST -> "POST"
  | `PUT -> "PUT"
  | `DELETE -> "DELETE"
  | `HEAD -> "HEAD"
  | `CONNECT -> "CONNECT"
  | `OPTIONS -> "OPTIONS"
  | `TRACE -> "TRACE"
  | `Other method_ -> method_

module Bigstring = Bigarray.Array1

(* TODO LATER It would be best if the web server would write straight into the
   framework's buffer, rather than first into its own, with copying to the
   framework following later. However, in the case of both http/af and h2, it
   appears that this will require at least a custom integration (at the same
   level as httpaf-lwt-unix), if it is currently possible at all. Fortunately,
   this will be an implementation detail of the framework, so we can profile and
   change it later, as an optimization. *)
type bigstring =
  (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigstring.t

let new_bigstring length =
  Bigstring.create Bigarray.char Bigarray.c_layout length

(* TODO LATER For now, Dream is following a simple model. The http server layer
   DOES NOT allocate a buffer, but stores a reading function in the request.
   When the body is actually needed by something in the web app, it is read to
   completion. *)
(* TODO LATER This exposes the framework to large request attacks. *)

(* Not every request will need body reading, so don't allocate a buffer for each
   requesst - only allocate it upon request. *)
type buffered_body = [
  | `Empty
  | `String of string
  | `Bigstring of bigstring
]

type body = [
  | buffered_body
  | `Bigstring_stream of (bigstring option -> unit) -> unit
  | `Reading of buffered_body Lwt.t
]

type incoming = {
  app : Hmap.t ref;
  client : string;
  method_ : method_;
  target : string;
  request_version : int * int;
}

include Status

type status = Status.t

type outgoing = {
  response_version : (int * int) option;
  status : status;
  reason : string option;
}

type 'a message = {
  specific : 'a;
  headers : (string * string) list;
  body : body ref;
  scope : Hmap.t;
}

type request = incoming message
type response = outgoing message


let response ?version ?(status = `OK) ?reason ?(headers = []) ?body () =
  let body =
    match body with
    | None -> `Empty
    | Some body -> `String body
  in
  {
    specific = {
      response_version = version;
      status;
      reason;
    };
    headers;
    body = ref body;
    scope = Hmap.empty;
  }

let client request =
  request.specific.client

let method_ request =
  request.specific.method_

let target request =
  request.specific.target

let status response =
  response.specific.status

let headers message =
  message.headers

let headers_named name message =
  let name = String.lowercase_ascii name in

  message.headers
  |> List.fold_left (fun matched (name', value) ->
    if String.lowercase_ascii name' = name then
      value::matched
    else
      matched)
    []
  |> List.rev

let header_basic name message =
  let name = String.lowercase_ascii name in
  message.headers
  |> List.find (fun (name', _) -> String.lowercase_ascii name' = name)
  |> snd

let header name message =
  try header_basic name message
  with Not_found -> Printf.ksprintf failwith "Header %s not found" name

let header_option name message =
  try Some (header_basic name message)
  with Not_found -> None

let has_header name message =
  try ignore (header_basic name message); true
  with Not_found -> false

let add_header name value message =
  {message with headers = (name, value)::message.headers}

(* TODO LATER This is the preliminary reader implementation described in
   comments above. It should eventually be replaced by a 0-copy reader, but that
   will likely require a much more low-level web server integration. *)
let buffer_body message : buffered_body Lwt.t =
  match !(message.body) with
  | #buffered_body as body -> Lwt.return body
  | `Reading on_finished -> on_finished

  | `Bigstring_stream stream ->
    let on_finished, finished = Lwt.wait () in
    message.body := `Reading on_finished;

    let rec read body length =
      stream begin function
      | None ->
        let body =
          if Bigstring.size_in_bytes body = 0 then
            `Empty
          else
          `Bigstring (Bigstring.sub body 0 length)
        in
        message.body := body;
        Lwt.wakeup_later finished body

      | Some chunk ->
        let chunk_length = Bigstring.size_in_bytes chunk in
        let new_length = length + chunk_length in
        let body =
          if new_length <= Bigstring.size_in_bytes body then
            body
          else
            let new_body = new_bigstring (new_length * 2) in
            Bigstring.blit
              (Bigstring.sub body 0 length) (Bigstring.sub new_body 0 length);
            new_body
        in
        Bigstring.blit chunk (Bigstring.sub body length chunk_length);
        read body new_length
      end
    in

    read (new_bigstring 4096) 0;

    on_finished

let body request =
  buffer_body request
  |> Lwt.map begin function
    | `Empty -> ""
    | `String body -> body
    | `Bigstring body -> Lwt_bytes.to_string body
  end

(* TODO LATER There need to be buffering and unbuffering version of this. The
   HTTP server needs a version that does not buffer. The app, by default,
   should get buffering. *)
let buffered_body_stream body =
  let sent = ref false in

  fun k ->
    if !sent then
      k None
    else begin
      sent := true;
      match body with
      | `Empty -> k None
      | `String body -> k (Some (Lwt_bytes.of_string body))
      | `Bigstring body -> k (Some body)
    end

let body_stream request =
  match !(request.body) with
  | #buffered_body as body -> buffered_body_stream body
  | `Bigstring_stream stream -> stream
  | `Reading on_finished ->
    fun k ->
      Lwt.on_success on_finished (fun body -> buffered_body_stream body k)

(* Create a fresh ref. The reason this field has a ref is because it might get
   replaced when a body is forced read. That's not what's happening here - we
   are setting a new body. Indeed, there might be a concurrent read going on.
   That read should not override the new body. So let it mutate the old
   request's ref; we generate a new request with a new body ref. *)
let with_body body response =
  {response with body = ref (`String body)}

let version_override response =
  response.specific.response_version

let reason_override response =
  response.specific.reason

type handler = request -> response Lwt.t
type middleware = handler -> handler

type 'a local = 'a Hmap.key

let new_local () =
  Hmap.Key.create ()

let local_option key message =
  Hmap.find key message.scope

let local key message =
  match local_option key message with
  | Some value -> value
  | None -> raise Not_found

let with_local key value message =
  {message with scope = Hmap.add key value message.scope}

type app = Hmap.t ref

let app () =
  ref Hmap.empty

type 'a global = {
  key : 'a Hmap.key;
  initializer_ : unit -> 'a;
}

let new_global ~initializer_ = {
  key = Hmap.Key.create ();
  initializer_;
}

let global {key; initializer_} request =
  match Hmap.find key !(request.specific.app) with
  | Some value -> value
  | None ->
    let value = initializer_ () in
    request.specific.app := Hmap.add key value !(request.specific.app);
    value

type ('a, 'b) log =
  ((?request:request ->
   ('a, Stdlib.Format.formatter, unit, 'b) Stdlib.format4 -> 'a) -> 'b) ->
    unit

let request ~app ~client ~method_ ~target ~version ~headers ~body = {
  specific = {
    app;
    client;
    method_;
    target;
    request_version = version;
  };
  headers;
  body = ref (`Bigstring_stream body);
  scope = Hmap.empty;
}
