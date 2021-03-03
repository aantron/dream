(* TODO LATER Proper decoder that goes component-by-component, avoids touching
   query strings (or should it?), and avoids decoding /, ?, etc. It will have to
   be UTF-8 aware, most likely -- however, the dangerous characters are not
   valid UTF-8 follower bytes anyway. Write tests for the thing. *)
let decode : Type.middleware = fun handler req ->
  handler {req with target = Uri.pct_decode req.target}
