module Hello_world
  (Pclock : Mirage_clock.PCLOCK)
  (Time : Mirage_time.S)
  (Stack : Tcpip.Stack.V4V6) =
struct
  module Dream =
    Dream__mirage.Mirage.Make (Pclock) (Time) (Stack)

  let start _pclock _time stack =
    Dream.http ~port:8080 (Stack.tcp stack)
    @@ Dream.logger
    @@ fun _ -> Dream.html "Good morning, world!"
end
