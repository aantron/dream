module Dream = Dream__pure.Inmost

val service :
     (Dream.app * Dream.handler)
  -> 'flow Alpn.info
  -> ('t -> ('flow, ([> `Closed | `Msg of string ] as 'error)) result Lwt.t)
  -> ('t -> unit Lwt.t)
  -> 't Paf.service
