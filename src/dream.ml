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

type incoming = {
  client : string;
  method_ : method_;
  target : string;
}

type status = [
  | `OK
]

type outgoing = {
  status : status;
  reason : string option;
}

type 'a message = {
  specific : 'a;
  version : int * int;
  headers : (string * string) list;
}

type request = incoming message
type response = outgoing message

(* TODO Make the version context-dependent, or take it from the request. *)
let response ?(version = (1, 1)) ?(status = `OK) ?reason () = {
  specific = {
    status;
    reason;
  };
  version;
  headers = [];
}

let status response =
  response.specific.status

let headers message =
  message.headers

type handler = request -> response Lwt.t
type middleware = handler -> handler

[@@@ocaml.warning "-49"]

module Httpaf = Dream_httpaf

let internal_create_request ~client ~method_ ~target ~version ~headers = {
  specific = {
    client;
    method_;
    target;
  };
  version;
  headers;
}
