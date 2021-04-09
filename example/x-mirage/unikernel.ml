open Lwt.Infix

module Make (Time : Mirage_time.S) (Stack : Mirage_stack.V4V6) = struct
  module HTTP = Dream.Make (Time) (Stack)

  let dream _ = Dream.respond "Hello World!"

  let start _ stack =
    let service = HTTP.service None dream in
    HTTP.init ~port:8080 stack >>= fun t ->
    let `Initialized th = HTTP.serve service t in th
end
