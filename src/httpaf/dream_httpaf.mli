type error_handler =
  Unix.sockaddr ->
  [ `Bad_request | `Bad_gateway | `Internal_server_error | `Exn of exn ] ->
    Dream.response Lwt.t

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?app:Dream.app ->
  ?error_handler:error_handler ->
  Dream.handler ->
    unit Lwt.t

val run :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?app:Dream.app ->
  ?error_handler:error_handler ->
  Dream.handler ->
    unit



(* TODO DOC that [stop] only stops the server listening - requests already
   in the server can continue executing. *)
(* TODO DOC Can probably also get `Exn upon failure to stream the body. *)
(* TODO DOC `Bad_gateway and `Internal_server_error occur when the application
   returns a negative content-length, or no content-length when one is
   required. *)
(* TODO DOC Can't even define the response type fully.. or can we? Can just
   reuse the Dream response, but note that the status will be ignored. *)
(* TODO DOC Figure out the behavior of various strings one could pass for the
   interface and DOCUMENT. *)
(* TODO DOC What happens if the error handler also raises an exception? *)
(* TODO DOC Placate the user: the error handler is generally not necessary. *)
