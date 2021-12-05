type request = Dream.request
type response = Dream.response
type 'a promise = 'a Lwt.t

type method_ = Dream.method_

val send : request -> response promise
