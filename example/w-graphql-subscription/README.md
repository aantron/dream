# `w-graphql-subscription`

<br>

This example sets up a GraphQL subscription, which receives events that count up
to 3:

![Subscription](https://raw.githubusercontent.com/aantron/dream/master/docs/asset/subscription.gif)

<br>

```ocaml
let count until =
  let stream, push = Lwt_stream.create () in
  let close () = push None in

  Lwt.async begin fun () ->
    let rec loop n =
      let%lwt () = Lwt_unix.sleep 0.5 in
      if n > until
      then (close (); Lwt.return_unit)
      else (push (Some n); loop (n + 1))
    in
    loop 1
  end;

  stream, close

let schema =
  let open Graphql_lwt.Schema in
  schema []
    ~subscriptions:[
      subscription_field "count"
        ~typ:(non_null int)
        ~args:Arg.[arg "until" ~typ:(non_null int)]
        ~resolve:(fun _info until ->
          Lwt.return (Ok (count until)))
    ]

let default_query =
  "subscription {\\n  count(until: 3)\\n}\\n"

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.origin_referrer_check
  @@ Dream.router [
    Dream.any "/graphql" (Dream.graphql Lwt.return schema);
    Dream.get "/" (Dream.graphiql ~default_query "/graphql");
  ]
```

<pre><code><b>$ cd example/w-graphql-subscriptions</b>
<b>$ npm install esy && npx esy</b>
<b>$ npx esy start</b></code></pre>

<br>

Visit [http://localhost:8080](http://localhost:8080) or the
[playground](http://dream.as/w-graphql-subscription), and run

```graphql
subscription {
  count(until: 3)
}
```

...and you should behavior like in the GIF above!

<br>

Subscriptions internally use a WebSocket protocol compatible with
[graphql-ws](https://github.com/enisdenjo/graphql-ws). This is a new protocol
that has succeeded the older
[subscriptions-transport-ws](https://github.com/apollographql/subscriptions-transport-ws),
though, internally, the two protocols are very
similar.

<br>

**See also:**

- [**`i-graphql`**](../i-graphql#files) for a basic GraphQL example.
- [**`k-websocket`**](../k-websocket#files) for direct WebSocket usage.

<br>

[Up to the example index](../#examples)
