(* TODO Redesign this API so that the promise does not resolve until
   the server stops running, so that no boilerplate is necessary to
   prevent the process from exiting. *)

(* TODO Document that [stop] only stops the server listening - requests already
   in the server can continue executing. *)

(* TODO Figure out the behavior of various strings one could pass for the
   interface and DOCUMENT. *)

(* TODO What happens if the error handler also raises an exception? *)

(* TODO Placate the user: the error handler is generally not necessary. *)

(* TODO Can't even define the response type fully.. or can we? Can just reuse
   the Dream response, but note that the status will be ignored. *)

(* TODO `Bad_gateway and `Internal_server_error occur when the application
   returns a negative content-length, or no content-length when one is
   required. *)

(* TODO Note that the never promise is still cancelable, however. Is this a
   good idea, though? On cancel, it will skip server shutdown. *)

(* TODO Can probably also get `Exn upon failure to stream the body. *)

type error_handler =
  Unix.sockaddr ->
  [ `Bad_request | `Bad_gateway | `Internal_server_error | `Exn of exn ] ->
    Dream.response Lwt.t

val serve :
  ?interface:string ->
  ?port:int ->
  ?stop:unit Lwt.t ->
  ?error_handler:error_handler ->
  Dream.handler ->
    unit Lwt.t

(* TODO Once the logger is implemented, need customize_default_error_handler. *)
