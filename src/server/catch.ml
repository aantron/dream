(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Message = Dream_pure.Message
module Status = Dream_pure.Status



type error = {
  condition : [
    | `Response of Message.response
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
  request : Message.request option;
  response : Message.response option;
  client : string option;
  severity : Log.log_level;
  will_send_response : bool;
}

type error_handler = error -> Message.response option

(* This error handler actually *is* a middleware, but it is just one pathway for
   reaching the centralized error handler provided by the user, so it is built
   into the framework. *)

(* TODO The option return value thing is pretty awkward. *)
let catch error_handler next_handler request =

  match next_handler request with
  | response ->
      let status = Message.status response in

      (* TODO Overfull hbox. *)
      if Status.is_client_error status || Status.is_server_error status then begin
        let caused_by, severity =
          if Status.is_client_error status then
            `Client, `Warning
          else
            `Server, `Error
        in

        let error = {
          condition = `Response response;
          layer = `App;
          caused_by;
          request = Some request;
          response = Some response;
          client = Some (Helpers.client request);
          severity = severity;
          will_send_response = true;
        } in

        error_handler error
      end
      else
        response

    (* This exception handler is partially redundant, in that the HTTP-level
       handlers will also catch exceptions. However, this handler is able to
       capture more relevant context. We leave the HTTP-level handlers for truly
       severe protocol-level errors and integration mistakes. *)
  | exception exn ->
      let error = {
        condition = `Exn exn;
        layer = `App;
        caused_by = `Server;
        request = Some request;
        response = None;
        client = Some (Helpers.client request);
        severity = `Error;
        will_send_response = true;
      } in

      error_handler error
