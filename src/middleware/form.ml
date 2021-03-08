module Dream =
struct
  include Dream_pure.Inmost
  module Log = Log
  let from_form_urlencoded = Microformat.from_form_urlencoded
end

let log =
  Dream.Log.source "dream.form"

let sort form =
  List.stable_sort (fun (key, _) (key', _) -> String.compare key key') form

(* TODO Debug metadata. *)
let key =
  Dream.new_local ()

(* TODO Add built-in Content-Type thing. *)
(* TODO Provide well-known Content-Types as predefined strings. *)
let urlencoded handler request =
  let open Lwt.Infix in

  match Dream.header_option "Content-Type" request with
  | Some "application/x-www-form-urlencoded" ->
    Dream.body request >>= fun body ->
    let form = sort (Dream.from_form_urlencoded body) in
    Dream.with_local key form request
    |> handler
  | content_type ->
    log.warning (fun m -> m ~request
      "Bad Content-Type '%s'" (Option.value content_type ~default:""));
    (* TODO Need a convenience function for generating a bad request. *)
    Dream.respond ~status:`Bad_request ""

(* TODO Use the optional. *)
let get request =
  Dream.local key request
  (* try
    Opium.Context.find_exn key req.env
  with exn ->
    Middleware.missing req name;
    raise exn *)

let consume field request =
  let form = get request in
  let matching, rest =
    List.partition (fun (field', _) -> field' = field) form in
  let matching = List.map snd matching in
  matching, Dream.with_local key rest request