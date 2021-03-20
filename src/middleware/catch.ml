(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Dream = Dream__pure.Inmost



(* This error handler actually *is* a middleware, but it is just one pathway for
   reaching the centralized error handler provided by the user, so it is built
   into the framework. *)

(* TODO The option thing is pretty awkward. *)
let catch user's_error_handler = fun next_handler request ->

  Lwt.try_bind

    (fun () ->
      next_handler request)

    (fun response ->
      let status = Dream.status response in

      if Dream.is_client_error status || Dream.is_server_error status then begin
        let caused_by, severity =
          if Dream.is_client_error status then
            `Client, `Warning
          else
            `Server, `Error
        in

        let error = Error.{
          condition = `Response response;
          layer = `App;
          caused_by;
          request = Some request;
          response = Some response;
          client = Some (Dream.client request);
          severity = severity;
          debug = Dream.debug (Dream.app request);
          will_send_response = true;
        } in

        user's_error_handler error
      end
      else
        Lwt.return response)

    (* This exception handler is partially redundant, in that the HTTP-level
       handlers will also catch exceptions. However, this handler is able to
       capture more relevant context. We leave the HTTP-level handlers for truly
       severe protocol-level errors and integration mistakes. *)
    (fun exn ->
      let error = Error.{
        condition = `Exn exn;
        layer = `App;
        caused_by = `Server;
        request = Some request;
        response = None;
        client = Some (Dream.client request);
        severity = `Error;
        debug = Dream.debug (Dream.app request);
        will_send_response = true;
      } in

      user's_error_handler error)
