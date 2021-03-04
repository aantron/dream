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

(* Not every request will need body reading, so don't allocate a buffer for each
   requesst - only allocate it upon request. *)
(* TODO LATER For now, Dream is following a simple model. The http server layer
   DOES NOT allocate a buffer, but stores a reading function in the request.
   When the body is actually needed by something in the web app, it is read to
   completion. *)
(* TODO LATER This exposes the framework to large request attacks. *)
(* TODO In case of connection: keep-alive or similar, don't we still need to at
   least skip the body to get the next request/frame? If so, the body reader
   will interact with the http layer. *)

type request_body_buffer = [
  | `Not_started
  | `Reading of bigstring Lwt.t
  | `Finished of bigstring
]

type incoming = {
  app : Hmap.t ref;
  client : string;
  method_ : method_;
  target : string;
  request_body_buffer : request_body_buffer ref;
  request_body_stream : (bigstring option -> unit) -> unit;
}

type status = [
  | `OK
]

let status_to_int = function
  | `OK -> 200

(* TODO Allow the response body to be either a string or a bigstring stream, as
   first-class kinds, so as to get zero-copy response output even with string
   streams. *)
type outgoing = {
  status : status;
  reason : string option;
  response_body_stream : (string option -> unit) -> unit;
}

type 'a message = {
  specific : 'a;
  version : int * int;
  headers : (string * string) list;
  scope : Hmap.t;
}

type request = incoming message
type response = outgoing message

(* TODO Make the version context-dependent, or take it from the request,
   probably with a middleware. *)
let response
    ?(version = (1, 1))
    ?(status = `OK)
    ?reason
    ?(headers = [])
    () =
  {
    specific = {
      status;
      reason;
      response_body_stream = (fun k -> k None);
    };
    version;
    headers;
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

(* TODO LATER This is the preliminary reader implementation described in
   comments above. It should eventually be replaced by a 0-copy reader, but that
   will likely require a much more low-level web server integration. *)
let receive_body request =
  match !(request.specific.request_body_buffer) with
  | `Finished body -> Lwt.return body
  | `Reading on_finished -> on_finished
  | `Not_started ->
    let on_finished, finished = Lwt.wait () in
    request.specific.request_body_buffer := `Reading on_finished;

    let rec read body length =
      request.specific.request_body_stream begin function
      | None ->
        let body = Bigstring.sub body 0 length in
        request.specific.request_body_buffer := `Finished body;
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
  receive_body request
  |> Lwt.map Lwt_bytes.to_string

let set_body_stream response stream =
  {response with specific =
    {response.specific with response_body_stream = stream}}

let set_body response body =
  let sent = ref false in
  set_body_stream response begin fun k ->
    if !sent then
      k None
    else begin
      sent := true;
      k (Some body)
    end
  end

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

let set_local key message value =
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

(* TODO Do uri parsing somewhre around here. *)
let internal_create_request
    ~app ~client ~method_ ~target ~version ~headers ~body_stream =
  {
    specific = {
      app;
      client;
      method_;
      target;
      request_body_buffer = ref `Not_started;
      request_body_stream = body_stream;
    };
    version;
    headers;
    scope = Hmap.empty;
  }

let internal_body_stream response =
  response.specific.response_body_stream
