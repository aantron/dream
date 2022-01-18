(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Message = Dream_pure.Message
module Stream = Dream_pure.Stream



let log =
  Log.sub_log "dream.origin"

(* TODO Rename all next_handler to inner_handler. *)
let origin_referrer_check inner_handler request =

  match Message.method_ request with
  | `GET | `HEAD ->
    inner_handler request

  | _ ->
    let origin =
      match Message.header request "Origin" with
      | Some "null" | None -> Message.header request "Referer"
      | Some _ as origin -> origin
    in

    match origin with
    | None ->
      log.warning (fun log -> log ~request
        "Origin and Referer headers both missing");
      Message.response ~status:`Bad_Request Stream.empty Stream.null

    (* TODO Also recommend Uri to users. *)
    | Some origin ->

      match Message.header request "Host" with
      | None ->
        log.warning (fun log -> log ~request "Host header missing");
        Message.response ~status:`Bad_Request Stream.empty Stream.null

      | Some host ->

        let origin_uri = Uri.of_string origin in

        let schemes_match =
          match Uri.scheme origin_uri with
          | Some "http" -> not (Helpers.https request)
          | Some "https" -> Helpers.https request
          | _ -> false
        in

        let host_host, host_port =
          match String.split_on_char ':' host with
          | [host; port] -> Some host, Some port
          | _ -> Some host, None
        in

        let origin_port =
          match Uri.port origin_uri with
          | None -> None
          | Some port -> Some (string_of_int port)
        in

        let hosts_match = Uri.host origin_uri = host_host
        and ports_match = origin_port = host_port in

        if schemes_match && hosts_match && ports_match then
          inner_handler request

        else begin
          log.warning (fun log -> log ~request
            "Origin-Host mismatch: '%s' vs. '%s'" origin host);
          Message.response ~status:`Bad_Request Stream.empty Stream.null
        end
