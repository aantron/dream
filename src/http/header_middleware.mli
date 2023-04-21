module Message = Dream_pure.Message
val drop_empty_headers :
  Message.handler -> Message.request -> Message.response Message.promise
