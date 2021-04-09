(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Method_and_status =
struct
  include Dream__pure.Method
  include Dream__pure.Status
end

include Dream__pure.Inmost

(* Eliminate optional arguments from the public interface for now. *)
let next ~bigstring ~close ~exn request =
  next ~bigstring ~close ~exn request

include Dream__middleware.Log
include Dream__middleware.Echo

let logger =
  Dream__middleware.Log.logger

let default_log =
  Dream__middleware.Log.sub_log (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

include Dream__middleware.Router
include Dream__middleware.Static

include Dream__middleware.Session
let sql_sessions = Dream__sql.Session.middleware

include Dream__middleware.Origin_referer_check
include Dream__middleware.Form
include Dream__middleware.Upload
include Dream__middleware.Csrf

let content_length =
  Dream__middleware.Content_length.content_length

include Dream__graphql.Graphql
include Dream__graphql.Graphiql
include Dream__sql.Sql

include Dream__middleware.Error
include Dream__http.Http

include Dream__middleware.Catch
include Dream__middleware.Request_id
include Dream__middleware.Site_prefix

let error_template =
  Dream__http.Error_handler.customize

let random =
  Dream__cipher.Random.random

include Dream__pure.Formats

let test ?(prefix = "") handler request =
  let app =
    content_length
    @@ assign_request_id
    @@ chop_site_prefix prefix
    @@ handler
  in

  Lwt_main.run (app request)

let log =
  Dream__middleware.Log.convenience_log

include Dream__middleware.Tag

module Make (Time : Mirage_time.S) (Stack : Mirage_stack.V4V6) = struct
  open Lwt.Infix

  include Paf_mirage.Make (Time) (Stack)

  let edn_of_flow flow =
    let ipaddr, port = Stack.TCP.dst flow in
    Fmt.str "%a:%d" Ipaddr.pp ipaddr port

  let alpn = function
    | `TCP _ -> None
    | `TLS (_, flow) -> match TLS.epoch flow with
      | Ok { Tls.Core.alpn_protocol; _ } -> alpn_protocol
      | _ -> None

  let peer = function
    | `TCP flow -> edn_of_flow flow
    | `TLS (edn, _) -> edn

  let injection = function
    | `TCP flow -> let module R = (val Mimic.repr tcp_protocol) in R.T flow
    | `TLS (_, flow) -> let module R = (val Mimic.repr tls_protocol) in R.T flow

  let info = { Alpn.alpn; peer; injection; }

  let service tls handler =
    let accept t =
      accept t >>= function
      | Error _ as err -> Lwt.return err
      | Ok flow -> match tls with
        | None -> Lwt.return_ok (`TCP flow)
        | Some tls ->
          let edn = edn_of_flow flow in
          TLS.server_of_flow tls flow >>= function
          | Ok flow -> Lwt.return_ok (`TLS (edn, flow))
          | Error err ->
            Stack.TCP.close flow >>= fun () ->
            Lwt.return_error (err :> [ TLS.write_error | `Msg of string ]) in
    let app = match tls with
      | Some _ -> let app = new_app () in app.https <- true ; app
      | None -> new_app () in
    Dream__mirage.service (app, handler) info accept close
end
