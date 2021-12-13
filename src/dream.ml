(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



include Dream_pure.Stream
include Dream_pure

include Dream__middleware.Log
include Dream__middleware.Log.Make (Ptime_clock)
(* Initalize logs with the default reporter which uses [Ptime_clock], this
   function is a part of [Dream__middleware.Log.Make], it's why it is not
   prepended by a module name. *)
let () =
  initialize ~setup_outputs:Fmt_tty.setup_std_outputs
include Dream__middleware.Echo

let default_log =
  Dream__middleware.Log.sub_log (Logs.Src.name Logs.default)

let error = default_log.error
let warning = default_log.warning
let info = default_log.info
let debug = default_log.debug

include Dream__middleware.Router
include Dream__unix.Static

include Dream__cipher.Cipher
include Dream__middleware.Cookie

include Dream__middleware.Session
include Dream__middleware.Session.Make (Ptime_clock)
let sql_sessions = Dream__sql.Session.middleware

include Dream__middleware.Flash

include Dream__middleware.Origin_referrer_check
include Dream__middleware.Form
include Dream__middleware.Upload
include Dream__middleware.Csrf

let content_length =
  Dream__middleware.Content_length.content_length

include Dream__graphql.Graphql
include Dream__sql.Sql

include Dream__http.Http

include Dream__middleware.Lowercase_headers
include Dream__middleware.Catch
include Dream__middleware.Request_id
include Dream__middleware.Site_prefix

let error_template =
  Dream__http.Error_handler.customize

let () = Dream__cipher.Random.initialize Mirage_crypto_rng_lwt.initialize

let random =
  Dream__cipher.Random.random

include Dream_pure.Formats

(* TODO Restore the ability to test with a prefix and re-enable the
   corresponding tests. *)
let test ?(prefix = "") handler request =
  ignore prefix;
  let app =
    content_length
    @@ assign_request_id
    @@ chop_site_prefix
    @@ handler
  in

  Lwt_main.run (app request)

let log =
  Dream__middleware.Log.convenience_log

include Dream__middleware.Tag

let respond ?status ?code ?headers body =
  let client_stream = stream (string body) no_writer
  and server_stream = stream no_reader no_writer in
  response ?status ?code ?headers client_stream server_stream
  |> Lwt.return

(* TODO Actually use the request and extract the site prefix. *)
let redirect ?status ?code ?headers _request location =
  let status = (status :> redirection option) in
  let status =
    match status, code with
    | None, None -> Some (`See_Other)
    | _ -> status
  in
  (* TODO The streams. *)
  let client_stream = stream empty no_writer
  and server_stream = stream no_reader no_writer in
  response ?status ?code ?headers client_stream server_stream
  |> with_header "Location" location
  |> Lwt.return

let stream ?status ?code ?headers f =
  (* TODO Streams. *)
  let client_stream = stream empty no_writer
  and server_stream = stream no_reader no_writer in
  let response =
    response ?status ?code ?headers client_stream server_stream
    |> with_stream
  in
  (* TODO Should set up an error handler for this. *)
  Lwt.async (fun () -> f response);
  Lwt.return response

let empty ?headers status =
  respond ?headers ~status ""

let not_found _ =
  respond ~status:`Not_Found ""

let now () = Ptime.to_float_s (Ptime.v (Ptime_clock.now_d_ps ()))

let form = form ~now
let multipart = multipart ~now
let csrf_token = csrf_token ~now
let verify_csrf_token = verify_csrf_token ~now
let form_tag ?method_ ?target ?enctype ?csrf_token ~action request =
  form_tag ~now ?method_ ?target ?enctype ?csrf_token ~action request

let request ?client ?method_ ?target ?version ?headers body =
  (* TODO Streams. *)
  let client_stream = Dream_pure.Stream.stream no_reader no_writer
  and server_stream = Dream_pure.Stream.stream (string body) no_writer in
  request ?client ?method_ ?target ?version ?headers client_stream server_stream

let response ?status ?code ?headers body =
  (* TODO Streams. *)
  let client_stream = Dream_pure.Stream.stream (string body) no_writer
  and server_stream = Dream_pure.Stream.stream no_reader no_writer in
  response ?status ?code ?headers client_stream server_stream
