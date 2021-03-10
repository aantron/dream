module Dream = Dream_pure.Inmost

type route

(* Leaf routes. *)
val get : string -> Dream.handler -> route
val post : string -> Dream.handler -> route

(* Route groups. *)
val apply : Dream.middleware list -> route list -> route

(* The middleware and the path parameter retriever. With respect to path
   parameters ("crumbs"), the middleware is the setter, and the retriever is,
   of course, the getter. *)
val router : route list -> Dream.middleware
val crumb : string -> Dream.request -> string
