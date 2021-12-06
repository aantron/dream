type request = Dream.request
type response = Dream.response
type 'a promise = 'a Lwt.t

type method_ = Dream.method_

type connection_pool

val send :
  ?connection_pool:connection_pool ->
    request -> response promise

(* TODO The issue with connections is that they depend on the underlying stack
   implementation, which is best kept as abstract as possible. That means the
   best way to do this is to make the connection type abstract to users, and to
   make all connection setup code internal to Hyper. That means the pool
   connection get function that is provided by the user will not create
   connections, so it must return options. *)
type connection
type host

val connection_pool :
  obtain:(host -> request -> connection option promise) ->
  return:(host -> request -> response -> connection -> (connection -> unit promise) -> unit promise) ->
    connection_pool
