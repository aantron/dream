(* From https://github.com/lyrm/ocaml-httpadapter/blob/master/src/http.mli

   Copyright (c) 2019 Carine Morel <carine@tarides.com>

   Permission to use, copy, modify, and distribute this software for any purpose
   with or without fee is hereby granted, provided that the above copyright
   notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
   REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
   AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
   INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
   LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
   OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
   PERFORMANCE OF THIS SOFTWARE. *)

type p = string * string

type encoding =
  | Encoding of string
  | Gzip
  | Compress
  | Deflate
  | Identity
  | Any

(** Accept-Encoding HTTP header parsing and generation *)

type q = int
(** Qualities are integers between 0 and 1000. A header with ["q=0.7"]
    corresponds to a quality of [700]. *)

type 'a qlist = (q * 'a) list
(** Lists, annotated with qualities. *)

val qsort : 'a qlist -> 'a qlist
(** Sort by quality, biggest first. Respect the initial ordering. *)

val encodings : string option -> encoding qlist
val string_of_encoding : ?q:q -> encoding -> string
val string_of_encodings : encoding qlist -> string