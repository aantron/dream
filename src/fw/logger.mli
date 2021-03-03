val log : Type.handler -> Type.handler

type ('a, 'b) log =
  ((?req:Opium.Request.t ->
   ('a, Stdlib.Format.formatter, unit, 'b) Stdlib.format4 -> 'a) -> 'b) ->
    unit

module type LOG =
sig
  val err : ('a, unit) log
  val warn : ('a, unit) log
  val info : ('a, unit) log
  val debug : ('a, unit) log
end

val create_log : string -> (module LOG)

val reporter : unit -> Logs.reporter

val request_id : Opium.Request.t -> int
