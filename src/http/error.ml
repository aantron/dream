(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream =
struct
  include Dream__pure.Inmost
  module Log = Dream__middleware.Log
end



type error = {
  condition : [
    | `Response of Dream.response
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
  request : Dream.request option;
  response : Dream.response option;
  client : string option;
  severity : Dream.Log.log_level;
  debug : bool;
  will_send_response : bool;
}

type error_handler = error -> Dream.response option Lwt.t
