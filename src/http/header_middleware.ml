
module Message = Dream_pure.Message

let drop_empty_headers (next_handler : Message.handler) (request: Message.request)   = 
  Message.drop_header request "";
  next_handler request
