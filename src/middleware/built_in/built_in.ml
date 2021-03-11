(* This file is part of Dream, released under the MIT license. See
   LICENSE.md for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Built-in middleware is functionality that is best written as middleware for
   maintainability purposes, but is actually a necessary part of Dream. Like the
   rest of what Dream does by default, built-in middleware...

   - Does not communicate with the client on its own.
   - Does not perform any expensive operations.

   The HTTP server integration and test helpers automatically apply built-in
   middleware on top of the handler passed in by the user. *)

let middleware =
   Request_id.assign
