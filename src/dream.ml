include Dream_

(* let assign_request_id = Request_id.assign_request_id *)

let identity handler request =
  handler request

let start handler request =
  handler request

let request_id =
  Request_id.assign

let log =
  Log.log_traffic

module Request_id = Request_id
module Log = Log

module Httpaf = Dream_httpaf [@@ocaml.warning "-49"]
