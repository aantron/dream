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

type incoming = {
  client : string;
  method_ : method_;
  target : string;
  app : Hmap.t ref;
}

type status = [
  | `OK
]

let status_to_int = function
  | `OK -> 200

type outgoing = {
  status : status;
  reason : string option;
}

type 'a message = {
  specific : 'a;
  version : int * int;
  headers : (string * string) list;
  scope : Hmap.t;
}

type request = incoming message
type response = outgoing message

(* TODO Make the version context-dependent, or take it from the request. *)
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

(* TODO Get rid of this module. *)
(* module App =
struct *)
type app = Hmap.t ref

let new_app () =
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
(* end *)

type ('a, 'b) log =
  ((?request:request ->
   ('a, Stdlib.Format.formatter, unit, 'b) Stdlib.format4 -> 'a) -> 'b) ->
    unit

(* TODO Do uri parsing somewhre around here. *)
let internal_create_request ~app ~client ~method_ ~target ~version ~headers = {
  specific = {
    client;
    method_;
    target;
    app;
  };
  version;
  headers;
  scope = Hmap.empty;
}
