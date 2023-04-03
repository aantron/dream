(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



module Message = Dream_pure.Message
module Stream = Dream_pure.Stream



let echo request =
  Message.response (Message.server_stream request) Stream.null
