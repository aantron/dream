(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* See also:

   - SEARCH, https://tools.ietf.org/html/draft-snell-search-method-02
   - Other WebDAV methods: COPY, LOCK, MKCOL, MOVE, PROPFIND, PROPPATCH,
     UNLOCK. *)

type method_ = [
  | `GET
  | `POST
  | `PUT
  | `DELETE
  | `HEAD
  | `CONNECT
  | `OPTIONS
  | `TRACE
  | `PATCH
  | `Method of string
]

let method_to_string = function
  | `GET -> "GET"
  | `POST -> "POST"
  | `PUT -> "PUT"
  | `DELETE -> "DELETE"
  | `HEAD -> "HEAD"
  | `CONNECT -> "CONNECT"
  | `OPTIONS -> "OPTIONS"
  | `TRACE -> "TRACE"
  | `PATCH -> "PATCH"
  | `Method method_ -> method_

let string_to_method = function
  | "GET" -> `GET
  | "POST" -> `POST
  | "PUT" -> `PUT
  | "DELETE" -> `DELETE
  | "HEAD" -> `HEAD
  | "CONNECT" -> `CONNECT
  | "OPTIONS" -> `OPTIONS
  | "TRACE" -> `TRACE
  | "PATCH" -> `PATCH
  | method_ -> `Method method_

let normalize_method method_ =
  match (method_ :> method_) with
  | `Method "GET" -> `GET
  | `Method "POST" -> `POST
  | `Method "PUT" -> `PUT
  | `Method "DELETE" -> `DELETE
  | `Method "HEAD" -> `HEAD
  | `Method "CONNECT" -> `CONNECT
  | `Method "OPTIONS" -> `OPTIONS
  | `Method "TRACE" -> `TRACE
  | `Method "PATCH" -> `PATCH
  | `Method _ as method_ -> method_
  | method_ -> method_

let methods_equal method_1 method_2 =
  normalize_method method_1 = normalize_method method_2
