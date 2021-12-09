type request = Dream.request
type response = Dream.response
type 'a promise = 'a Lwt.t



type connection_pool

val send :
  ?connection_pool:connection_pool ->
    request -> response promise



type connection
type endpoint
type create_result = {
  connection : connection;
  destroy : connection -> unit promise;
  concurrency : [ `Single_use | `Sequence | `Pipeline | `Multiplex ];
}
type create = endpoint -> create_result promise

val connection_pool :
  obtain:(endpoint -> request -> create -> (connection * int64) promise) ->
  write_done:(int64 -> unit) ->
  all_done:(int64 -> response -> unit) ->
  error:(int64 -> unit) ->
    connection_pool
