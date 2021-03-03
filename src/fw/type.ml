(* TODO ORganize this. *)

type handler = Opium.Request.t -> Opium.Response.t Lwt.t
type middleware = handler -> handler
