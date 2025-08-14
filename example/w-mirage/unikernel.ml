module Hello_world
  (Stack : Tcpip.Stack.V4V6) =
struct
  module Dream =
    Dream__mirage.Mirage.Make (Stack)

  let start stack =
    Dream.http ~port:8080 (Stack.tcp stack)
    @@ Dream.logger
    @@ fun _ -> Dream.html "Good morning, world!"
end
